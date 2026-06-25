import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '@app/common';
import { FilesService } from '@app/files';

/**
 * Контекст наблюдателя сводки. Полностью совпадает с ProjectSummaryService,
 * см. там подробности по правилам ролевой видимости (§1.4 / §3.2 / §9.3).
 */
export interface ReportViewer {
  userId: string;
  isOwner: boolean;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  assignedStageIds: string[];
  foremanStageIds: string[];
  canSeeProjectBudget: boolean;
  canSeeStageBudget: boolean;
  canSeeAllPayments: boolean;
}

interface UserLite {
  id: string;
  firstName: string;
  lastName: string;
  phone?: string | null;
}

/**
 * Структура данных, собранных из БД — отдельно, чтобы тесты могли проверять
 * `buildHtml(data)` детерминированно, без mock-а puppeteer и без сетевых вызовов.
 */
export interface ReportData {
  generatedAt: Date;
  generatedBy: UserLite;
  viewerRoleLabel: string;
  project: {
    id: string;
    title: string;
    address: string | null;
    description: string | null;
    status: string;
    progressCache: number;
    semaphoreCache: string;
    workBudget: bigint;
    materialsBudget: bigint;
    plannedStart: Date | null;
    plannedEnd: Date | null;
    createdAt: Date;
    archivedAt: Date | null;
    owner: UserLite;
  };
  team: Array<{
    user: UserLite;
    role: string;
    invitedByName: string | null;
    stageNames: string[];
    isHidden: boolean;
  }>;
  stages: Array<{
    id: string;
    title: string;
    orderIndex: number;
    status: string;
    pendingApproval: boolean;
    plannedStart: Date | null;
    plannedEnd: Date | null;
    startedAt: Date | null;
    doneAt: Date | null;
    progressCache: number;
    workBudget: bigint;
    materialsBudget: bigint;
    foremanNames: string[];
    masterName: string;
    pauses: Array<{
      startedAt: Date;
      endedAt: Date | null;
      reason: string;
      comment: string | null;
    }>;
    steps: Array<{
      id: string;
      title: string;
      orderIndex: number;
      status: string;
      description: string | null;
      whatDid: string | null;
      howDid: string | null;
      price: bigint | null;
      doneAt: Date | null;
      doneByName: string | null;
      photos: Array<{ id: string; dataUrl: string | null; fileKey: string }>;
      substeps: Array<{ text: string; isDone: boolean; doneAt: Date | null }>;
      questions: Array<{
        text: string;
        authorName: string;
        addresseeName: string;
        status: string;
        answer: string | null;
        answeredAt: Date | null;
      }>;
    }>;
  }>;
  payments: Array<{
    createdAt: Date;
    kind: string;
    amount: bigint;
    fromName: string;
    toName: string;
    stageName: string;
    comment: string | null;
    photoDataUrl: string | null;
  }>;
  materials: Array<{
    createdAt: Date;
    title: string;
    status: string;
    recipient: string;
    stageName: string;
    comment: string | null;
    deliveredAt: Date | null;
    items: Array<{
      name: string;
      qty: string;
      unit: string | null;
      pricePerUnit: bigint | null;
      totalPrice: bigint | null;
      isBought: boolean;
    }>;
  }>;
  selfPurchases: Array<{
    createdAt: Date;
    byName: string;
    byRole: string;
    addresseeName: string;
    amount: bigint;
    status: string;
    comment: string | null;
    stageName: string;
    photoDataUrls: string[];
  }>;
  tools: Array<{
    issuedAt: Date;
    toolName: string;
    serial: string | null;
    qty: number;
    toName: string;
    issuedByName: string;
    status: string;
    stageName: string;
    confirmedAt: Date | null;
    returnedAt: Date | null;
  }>;
  documents: Array<{
    title: string;
    category: string;
    mimeType: string;
    sizeBytes: number;
    uploadedByName: string;
    createdAt: Date;
    fileKey: string;
    downloadUrl: string | null;
  }>;
  feed: Array<{
    createdAt: Date;
    kind: string;
    actorName: string;
    stageName: string | null;
    description: string;
  }>;
  budgetSummary: {
    canSeeProjectBudget: boolean;
    canSeeStageBudget: boolean;
    work: bigint;
    materials: bigint;
    total: bigint;
    byStage: Array<{
      stageName: string;
      work: bigint;
      materials: bigint;
    }>;
  };
}

/**
 * Полный отчёт по проекту в PDF. Включает все домены (бюджет, этапы, шаги
 * с фото, материалы, инструменты, документы, движение денег, ленту).
 * Качество — для предъявления к юр. документам: данные подаются в виде
 * таблиц, фотофиксация встроена inline, шапка/футер «Создано в Repair Control»
 * с штампом времени и автора экспорта.
 */
@Injectable()
export class ProjectReportPdfService {
  private readonly logger = new Logger(ProjectReportPdfService.name);
  /** Максимальное число фото шага, встраиваемых в PDF (защита от мегабайтных отчётов). */
  private static readonly MAX_PHOTOS_PER_STEP = 12;
  /** Лимит на встраиваемое одно фото (после которого подставляется ссылка). */
  private static readonly MAX_PHOTO_BYTES = 3 * 1024 * 1024;

  constructor(
    private readonly prisma: PrismaService,
    private readonly files: FilesService,
  ) {}

  async build(projectId: string, viewer: ReportViewer, stageId?: string): Promise<Buffer> {
    const data = await this.collect(projectId, viewer, stageId);
    if (!data) {
      return this.fallbackPlain(`Проект ${projectId} не найден.`);
    }
    const html = this.buildHtml(data);
    return this.renderPdf(html);
  }

  // -------------------- DATA COLLECTION --------------------

  /// NEWFIX §7.1 — если задан `stageIdFilter`, отчёт ограничивается одним
  /// этапом (после применения RBAC-фильтра видимости).
  async collect(
    projectId: string,
    viewer: ReportViewer,
    stageIdFilter?: string,
  ): Promise<ReportData | null> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      include: {
        owner: { select: { id: true, firstName: true, lastName: true, phone: true } },
      },
    });
    if (!project) return null;

    const visibleStageIdSet = this.computeVisibleStageIds(viewer);

    const baseStageWhere =
      viewer.isOwner ||
      viewer.membershipRole === 'representative' ||
      viewer.membershipRole === 'customer'
        ? { projectId }
        : visibleStageIdSet
          ? { projectId, id: { in: [...visibleStageIdSet] } }
          : { projectId, id: { in: [] } };
    // NEWFIX §7.1 — Stage-level отчёт: дополнительный фильтр по конкретному
    // stageId (поверх RBAC visibility-фильтра).
    const stageWhere = stageIdFilter ? { ...baseStageWhere, id: stageIdFilter } : baseStageWhere;
    const stagesRaw = await this.prisma.stage.findMany({
      where: stageWhere,
      orderBy: { orderIndex: 'asc' },
      include: {
        pauses: { orderBy: { startedAt: 'asc' } },
        steps: {
          orderBy: { orderIndex: 'asc' },
          include: {
            photos: { orderBy: { createdAt: 'asc' } },
            substeps: { orderBy: { createdAt: 'asc' } },
            questions: { orderBy: { createdAt: 'asc' } },
          },
        },
      },
    });

    const visibleStageIds = stagesRaw.map((s) => s.id);
    const visibleStageIdsSet = new Set(visibleStageIds);

    const allMemberships = await this.prisma.membership.findMany({
      where: { projectId, removedAt: null },
      include: {
        user: { select: { id: true, firstName: true, lastName: true, phone: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    const documents = await this.prisma.document.findMany({
      where: {
        projectId,
        deletedAt: null,
        ...(visibleStageIdSet
          ? { OR: [{ stageId: null }, { stageId: { in: visibleStageIds } }] }
          : {}),
      },
      orderBy: [{ category: 'asc' }, { createdAt: 'asc' }],
    });

    const payments = await this.loadPayments(projectId, viewer, visibleStageIds);
    const materials = await this.loadMaterials(projectId, viewer, visibleStageIds);
    const selfPurchases = await this.loadSelfPurchases(projectId, viewer, visibleStageIds);
    const tools = await this.loadTools(projectId, viewer, visibleStageIds);
    const feed = await this.loadFeed(projectId, viewer, visibleStageIdsSet);

    const userIds = new Set<string>([project.ownerId, viewer.userId]);
    allMemberships.forEach((m) => userIds.add(m.userId));
    stagesRaw.forEach((s) => {
      s.foremanIds.forEach((id) => userIds.add(id));
      if (s.masterId) userIds.add(s.masterId);
      s.steps.forEach((st) => {
        if (st.doneById) userIds.add(st.doneById);
        st.questions.forEach((q) => {
          userIds.add(q.authorId);
          userIds.add(q.addresseeId);
        });
      });
    });
    payments.forEach((p) => {
      userIds.add(p.fromUserId);
      userIds.add(p.toUserId);
    });
    selfPurchases.forEach((s) => {
      userIds.add(s.byUserId);
      userIds.add(s.addresseeId);
    });
    tools.forEach((t) => {
      userIds.add(t.toUserId);
      userIds.add(t.issuedById);
    });
    feed.forEach((f) => {
      if (f.actorId) userIds.add(f.actorId);
    });
    allMemberships.forEach((m) => {
      if (m.invitedById) userIds.add(m.invitedById);
    });

    const users =
      userIds.size > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: [...userIds] } },
            select: { id: true, firstName: true, lastName: true, phone: true },
          })
        : [];
    const usersById = new Map<string, UserLite>(users.map((u) => [u.id, u]));

    const toolItemIds = new Set<string>();
    tools.forEach((t) => toolItemIds.add(t.toolItemId));
    const toolItems =
      toolItemIds.size > 0
        ? await this.prisma.toolItem.findMany({
            where: { id: { in: [...toolItemIds] } },
          })
        : [];
    const toolItemsById = new Map<string, (typeof toolItems)[number]>(
      toolItems.map((t) => [t.id, t]),
    );

    const hiddenUserIds = this.computeHiddenUserIds(allMemberships, viewer);

    const fmtUser = (id: string | null | undefined): string => {
      if (!id) return '—';
      if (hiddenUserIds.has(id)) return 'Субподрядчик бригадира (скрыт)';
      const u = usersById.get(id);
      return u ? `${u.firstName} ${u.lastName}`.trim() : id;
    };

    const stageNameById = new Map<string, string>(stagesRaw.map((s) => [s.id, s.title]));

    // Загружаем фото шагов в base64 параллельно.
    const photoData = new Map<string, string>(); // photoId → dataUrl
    const photoFetches: Array<Promise<void>> = [];
    for (const s of stagesRaw) {
      for (const st of s.steps) {
        const limited = st.photos.slice(0, ProjectReportPdfService.MAX_PHOTOS_PER_STEP);
        for (const ph of limited) {
          photoFetches.push(
            this.fetchAsDataUrl(ph.fileKey, ph.mimeType ?? 'image/jpeg').then((url) => {
              if (url) photoData.set(ph.id, url);
            }),
          );
        }
      }
    }

    // Чеки платежей и фото самозакупов.
    const paymentPhotoData = new Map<string, string>();
    for (const p of payments) {
      if (p.photoKey) {
        photoFetches.push(
          this.fetchAsDataUrl(p.photoKey, 'image/jpeg').then((url) => {
            if (url) paymentPhotoData.set(p.id, url);
          }),
        );
      }
    }
    const selfPurchasePhotoData = new Map<string, string[]>();
    for (const s of selfPurchases) {
      if (s.photoKeys && s.photoKeys.length > 0) {
        const urls: string[] = [];
        selfPurchasePhotoData.set(s.id, urls);
        for (const key of s.photoKeys.slice(0, 6)) {
          photoFetches.push(
            this.fetchAsDataUrl(key, 'image/jpeg').then((url) => {
              if (url) urls.push(url);
            }),
          );
        }
      }
    }
    await Promise.all(photoFetches);

    const team = this.filterTeam(allMemberships, viewer, stagesRaw).map((m) => ({
      user: m.user as UserLite,
      role: m.role,
      invitedByName: m.invitedById ? fmtUser(m.invitedById) : null,
      stageNames:
        m.stageIds.length > 0 ? m.stageIds.map((sid) => stageNameById.get(sid) ?? sid) : [],
      isHidden: false,
    }));

    const stages = stagesRaw.map((s) => ({
      id: s.id,
      title: s.title,
      orderIndex: s.orderIndex,
      status: s.status,
      pendingApproval: s.pendingApproval,
      plannedStart: s.plannedStart,
      plannedEnd: s.plannedEnd,
      startedAt: s.startedAt,
      doneAt: s.doneAt,
      progressCache: s.progressCache,
      workBudget: s.workBudget,
      materialsBudget: s.materialsBudget,
      foremanNames: s.foremanIds.length > 0 ? s.foremanIds.map(fmtUser) : [],
      masterName: fmtUser(s.masterId),
      pauses: s.pauses.map((p) => ({
        startedAt: p.startedAt,
        endedAt: p.endedAt,
        reason: p.reason,
        comment: p.comment,
      })),
      steps: s.steps.map((st) => ({
        id: st.id,
        title: st.title,
        orderIndex: st.orderIndex,
        status: st.status,
        description: st.description,
        whatDid: st.whatDid,
        howDid: st.howDid,
        price: st.price,
        doneAt: st.doneAt,
        doneByName: st.doneById ? fmtUser(st.doneById) : null,
        photos: st.photos.slice(0, ProjectReportPdfService.MAX_PHOTOS_PER_STEP).map((ph) => ({
          id: ph.id,
          fileKey: ph.fileKey,
          dataUrl: photoData.get(ph.id) ?? null,
        })),
        substeps: st.substeps.map((ss) => ({
          text: ss.text,
          isDone: ss.isDone,
          doneAt: ss.doneAt,
        })),
        questions: st.questions.map((q) => ({
          text: q.text,
          authorName: fmtUser(q.authorId),
          addresseeName: fmtUser(q.addresseeId),
          status: q.status,
          answer: q.answer,
          answeredAt: q.answeredAt,
        })),
      })),
    }));

    const paymentsRendered = payments.map((p) => ({
      createdAt: p.createdAt,
      kind: p.kind,
      amount: p.amount,
      fromName: fmtUser(p.fromUserId),
      toName: fmtUser(p.toUserId),
      stageName: p.stageId ? (stageNameById.get(p.stageId) ?? 'этап удалён') : 'проект',
      comment: p.comment,
      photoDataUrl: paymentPhotoData.get(p.id) ?? null,
    }));

    const materialsRendered = materials.map((m) => ({
      createdAt: m.createdAt,
      title: m.title,
      status: m.status,
      recipient: m.recipient,
      stageName: m.stageId ? (stageNameById.get(m.stageId) ?? 'этап удалён') : 'проект',
      comment: m.comment,
      deliveredAt: m.deliveredAt,
      items: m.items.map((it) => ({
        name: it.name,
        qty:
          typeof it.qty === 'object' && it.qty !== null
            ? (it.qty as { toString(): string }).toString()
            : String(it.qty),
        unit: it.unit,
        pricePerUnit: it.pricePerUnit,
        totalPrice: it.totalPrice,
        isBought: it.isBought,
      })),
    }));

    const selfPurchasesRendered = selfPurchases.map((s) => ({
      createdAt: s.createdAt,
      byName: fmtUser(s.byUserId),
      byRole: s.byRole,
      addresseeName: fmtUser(s.addresseeId),
      amount: s.amount,
      status: s.status,
      comment: s.comment,
      stageName: s.stageId ? (stageNameById.get(s.stageId) ?? 'этап удалён') : 'проект',
      photoDataUrls: selfPurchasePhotoData.get(s.id) ?? [],
    }));

    const toolsRendered = tools.map((t) => {
      const ti = toolItemsById.get(t.toolItemId);
      return {
        issuedAt: t.issuedAt,
        toolName: ti?.name ?? '—',
        serial: ti?.serial ?? null,
        qty: t.qty,
        toName: fmtUser(t.toUserId),
        issuedByName: fmtUser(t.issuedById),
        status: t.status,
        stageName: t.stageId ? (stageNameById.get(t.stageId) ?? 'этап удалён') : 'проект',
        confirmedAt: t.confirmedAt,
        returnedAt: t.returnedAt,
      };
    });

    // Документы — без встраивания (могут быть PDF/DOCX/XLSX), даём presigned ссылку.
    const documentsRendered: ReportData['documents'] = [];
    for (const d of documents) {
      let url: string | null = null;
      try {
        const { url: signed } = await this.files.createPresignedDownload(d.fileKey);
        url = signed;
      } catch {
        url = null;
      }
      documentsRendered.push({
        title: d.title,
        category: d.category,
        mimeType: d.mimeType,
        sizeBytes: d.sizeBytes,
        uploadedByName: fmtUser(d.uploadedById),
        createdAt: d.createdAt,
        fileKey: d.fileKey,
        downloadUrl: url,
      });
    }

    const feedRendered = feed.map((f) => ({
      createdAt: f.createdAt,
      kind: f.kind,
      actorName: f.actorId ? fmtUser(f.actorId) : 'система',
      stageName: f.stageId ? (stageNameById.get(f.stageId) ?? null) : null,
      description: this.describeFeedEvent(f.kind, f.payload as Record<string, unknown>),
    }));

    const budgetSummary = {
      canSeeProjectBudget: viewer.canSeeProjectBudget,
      canSeeStageBudget: viewer.canSeeStageBudget,
      work: project.workBudget,
      materials: project.materialsBudget,
      total: BigInt(project.workBudget) + BigInt(project.materialsBudget),
      byStage: stagesRaw.map((s) => ({
        stageName: s.title,
        work: s.workBudget,
        materials: s.materialsBudget,
      })),
    };

    const generatedBy = usersById.get(viewer.userId) ?? {
      id: viewer.userId,
      firstName: '—',
      lastName: '',
    };

    return {
      generatedAt: new Date(),
      generatedBy,
      viewerRoleLabel: this.fmtRole(viewer.membershipRole ?? (viewer.isOwner ? 'owner' : 'member')),
      project: {
        id: project.id,
        title: project.title,
        address: project.address,
        description: project.description,
        status: project.status,
        progressCache: project.progressCache,
        semaphoreCache: project.semaphoreCache,
        workBudget: project.workBudget,
        materialsBudget: project.materialsBudget,
        plannedStart: project.plannedStart,
        plannedEnd: project.plannedEnd,
        createdAt: project.createdAt,
        archivedAt: project.archivedAt,
        owner: project.owner as UserLite,
      },
      team,
      stages,
      payments: paymentsRendered,
      materials: materialsRendered,
      selfPurchases: selfPurchasesRendered,
      tools: toolsRendered,
      documents: documentsRendered,
      feed: feedRendered,
      budgetSummary,
    };
  }

  // -------------------- HTML --------------------

  buildHtml(d: ReportData): string {
    const fmtDate = (date?: Date | null): string => {
      if (!date) return '—';
      const day = date.getUTCDate().toString().padStart(2, '0');
      const mon = (date.getUTCMonth() + 1).toString().padStart(2, '0');
      return `${day}.${mon}.${date.getUTCFullYear()}`;
    };
    const fmtDateTime = (date?: Date | null): string => {
      if (!date) return '—';
      const h = date.getUTCHours().toString().padStart(2, '0');
      const m = date.getUTCMinutes().toString().padStart(2, '0');
      return `${fmtDate(date)} ${h}:${m} UTC`;
    };
    const fmtMoney = (v?: bigint | number | null): string => {
      if (v === null || v === undefined) return '—';
      const rub = Math.round(Number(v) / 100);
      return `${rub.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} ₽`;
    };
    const semaphoreColor = (s: string): string =>
      (
        ({ green: '#15B097', yellow: '#F2A93B', red: '#E5484D', plan: '#6E7AAA' }) as Record<
          string,
          string
        >
      )[s] ?? '#6E7AAA';

    const headerBranding = `
      <div class="branding">
        <div class="brand-mark">Repair Control</div>
        <div class="brand-sub">Платформа контроля ремонта · отчёт по проекту</div>
      </div>`;

    const cover = `
      <section class="cover">
        ${headerBranding}
        <h1>${escapeHtml(d.project.title)}</h1>
        <div class="cover-meta">
          <div><span class="lbl">Адрес</span><span class="val">${escapeHtml(
            d.project.address ?? '—',
          )}</span></div>
          <div><span class="lbl">Статус</span><span class="val">${escapeHtml(
            this.fmtProjectStatus(d.project.status),
          )}</span></div>
          <div><span class="lbl">Прогресс</span><span class="val">
            <span class="dot" style="background:${semaphoreColor(d.project.semaphoreCache)}"></span>
            ${d.project.progressCache}% · светофор ${escapeHtml(d.project.semaphoreCache)}
          </span></div>
          <div><span class="lbl">Заказчик</span><span class="val">${escapeHtml(
            `${d.project.owner.firstName} ${d.project.owner.lastName}`.trim(),
          )}${d.project.owner.phone ? ` · ${escapeHtml(d.project.owner.phone)}` : ''}</span></div>
          <div><span class="lbl">Плановые сроки</span><span class="val">${fmtDate(
            d.project.plannedStart,
          )} → ${fmtDate(d.project.plannedEnd)}</span></div>
          <div><span class="lbl">Создан</span><span class="val">${fmtDate(
            d.project.createdAt,
          )}</span></div>
          ${
            d.project.archivedAt
              ? `<div><span class="lbl">Архивирован</span><span class="val">${fmtDate(d.project.archivedAt)}</span></div>`
              : ''
          }
        </div>
        ${
          d.project.description
            ? `<div class="cover-descr"><div class="lbl">Описание</div><div>${escapeHtml(
                d.project.description,
              )}</div></div>`
            : ''
        }
        <div class="cover-stamp">
          Отчёт сформирован ${fmtDateTime(d.generatedAt)}<br/>
          Запросил: ${escapeHtml(
            `${d.generatedBy.firstName} ${d.generatedBy.lastName}`.trim(),
          )} (${escapeHtml(d.viewerRoleLabel)})<br/>
          Идентификатор проекта: <code>${escapeHtml(d.project.id)}</code>
        </div>
      </section>`;

    const budgetSection = `
      <section class="page-break">
        <h2>Бюджет</h2>
        ${
          d.budgetSummary.canSeeProjectBudget
            ? `<table class="kv">
                <tr><th>Работы</th><td>${fmtMoney(d.budgetSummary.work)}</td></tr>
                <tr><th>Материалы</th><td>${fmtMoney(d.budgetSummary.materials)}</td></tr>
                <tr class="total"><th>Итого</th><td>${fmtMoney(d.budgetSummary.total)}</td></tr>
              </table>`
            : d.budgetSummary.canSeeStageBudget
              ? `<p class="muted">Общий бюджет проекта скрыт по правам. Ниже — бюджет этапов, к которым у вас есть доступ.</p>`
              : `<p class="muted">(Бюджет скрыт — нет права просмотра финансов)</p>`
        }
        ${
          (d.budgetSummary.canSeeProjectBudget || d.budgetSummary.canSeeStageBudget) &&
          d.budgetSummary.byStage.length > 0
            ? `<h3>По этапам</h3>
              <table class="grid">
                <thead><tr><th>Этап</th><th class="num">Работы</th><th class="num">Материалы</th><th class="num">Итого</th></tr></thead>
                <tbody>
                ${d.budgetSummary.byStage
                  .map(
                    (b) => `<tr>
                      <td>${escapeHtml(b.stageName)}</td>
                      <td class="num">${fmtMoney(b.work)}</td>
                      <td class="num">${fmtMoney(b.materials)}</td>
                      <td class="num"><b>${fmtMoney(BigInt(b.work) + BigInt(b.materials))}</b></td>
                    </tr>`,
                  )
                  .join('')}
                </tbody>
              </table>`
            : ''
        }
      </section>`;

    const paymentsSection = `
      <section class="page-break">
        <h2>Движение средств (${d.payments.length})</h2>
        ${
          d.payments.length === 0
            ? `<p class="muted">Финансовых проводок нет.</p>`
            : `<table class="grid">
                <thead><tr>
                  <th>Дата</th><th>Тип</th>
                  <th class="num">Сумма</th><th>Откуда → Куда</th><th>Этап</th><th>Комментарий</th>
                </tr></thead>
                <tbody>
                ${d.payments
                  .map(
                    (p) => `<tr>
                      <td class="nowrap">${fmtDate(p.createdAt)}</td>
                      <td>${escapeHtml(this.fmtPaymentKind(p.kind))}</td>
                      <td class="num"><b>${fmtMoney(p.amount)}</b></td>
                      <td>${escapeHtml(p.fromName)} → ${escapeHtml(p.toName)}</td>
                      <td>${escapeHtml(p.stageName)}</td>
                      <td>${p.comment ? escapeHtml(p.comment) : '—'}</td>
                    </tr>${
                      p.photoDataUrl
                        ? `<tr class="receipt"><td colspan="6"><div class="receipt-block">
                            <span class="lbl">Чек:</span><img src="${p.photoDataUrl}" alt="receipt"/>
                          </div></td></tr>`
                        : ''
                    }`,
                  )
                  .join('')}
                </tbody>
              </table>`
        }
      </section>`;

    const teamSection = `
      <section class="page-break">
        <h2>Команда (${d.team.length})</h2>
        ${
          d.team.length === 0
            ? `<p class="muted">Участников нет.</p>`
            : `<table class="grid">
                <thead><tr><th>Участник</th><th>Роль</th><th>Телефон</th><th>Этапы</th></tr></thead>
                <tbody>
                ${d.team
                  .map(
                    (m) => `<tr>
                      <td>${escapeHtml(`${m.user.firstName} ${m.user.lastName}`.trim())}</td>
                      <td>${escapeHtml(this.fmtRole(m.role))}</td>
                      <td>${escapeHtml(m.user.phone ?? '—')}</td>
                      <td>${
                        m.stageNames.length > 0
                          ? m.stageNames.map((n) => escapeHtml(n)).join(', ')
                          : '<span class="muted">весь проект</span>'
                      }</td>
                    </tr>`,
                  )
                  .join('')}
                </tbody>
              </table>`
        }
      </section>`;

    const stageStatusPill = (status: string, pending: boolean): string => {
      const label = this.fmtStageStatus(status) + (pending ? ' (ждёт согл.)' : '');
      return this.statusPill(status, label);
    };

    const stagesSection = `
      <section class="page-break">
        <h2>Этапы (${d.stages.length})</h2>
        ${
          d.stages.length === 0
            ? `<p class="muted">Этапов нет или нет доступа.</p>`
            : d.stages
                .map(
                  (s, idx) => `
              <article class="stage ${idx > 0 ? 'page-break' : ''}">
                <h3>Этап ${s.orderIndex + 1}. ${escapeHtml(s.title)}</h3>
                <table class="kv compact">
                  <tr><th>Статус</th><td>${stageStatusPill(s.status, s.pendingApproval)}</td></tr>
                  <tr><th>План</th><td>${fmtDate(s.plannedStart)} → ${fmtDate(s.plannedEnd)}</td></tr>
                  ${s.startedAt ? `<tr><th>Начат</th><td>${fmtDate(s.startedAt)}</td></tr>` : ''}
                  ${s.doneAt ? `<tr><th>Завершён</th><td>${fmtDate(s.doneAt)}</td></tr>` : ''}
                  <tr><th>Прогресс</th><td>${s.progressCache}%</td></tr>
                  <tr><th>Бригадир</th><td>${
                    s.foremanNames.length > 0
                      ? s.foremanNames.map((n) => escapeHtml(n)).join(', ')
                      : '—'
                  }</td></tr>
                  <tr><th>Мастер</th><td>${escapeHtml(s.masterName)}</td></tr>
                  ${
                    d.budgetSummary.canSeeStageBudget
                      ? `<tr><th>Бюджет этапа</th><td>работы ${fmtMoney(
                          s.workBudget,
                        )} · материалы ${fmtMoney(s.materialsBudget)}</td></tr>`
                      : ''
                  }
                </table>
                ${
                  s.pauses.length > 0
                    ? `<h4>Паузы (${s.pauses.length})</h4>
                      <table class="grid"><thead><tr><th>С</th><th>По</th><th>Причина</th><th>Комментарий</th></tr></thead>
                      <tbody>${s.pauses
                        .map(
                          (p) => `<tr>
                            <td class="nowrap">${fmtDate(p.startedAt)}</td>
                            <td class="nowrap">${p.endedAt ? fmtDate(p.endedAt) : 'продолжается'}</td>
                            <td>${escapeHtml(p.reason)}</td>
                            <td>${p.comment ? escapeHtml(p.comment) : '—'}</td>
                          </tr>`,
                        )
                        .join('')}</tbody></table>`
                    : ''
                }
                ${
                  s.steps.length > 0
                    ? `<h4>Шаги (${s.steps.length})</h4>
                      ${s.steps
                        .map(
                          (st) => `
                            <div class="step">
                              <div class="step-header">
                                <span class="step-no">${st.orderIndex + 1}.</span>
                                <span class="step-title">${escapeHtml(st.title)}</span>
                                ${this.statusPill(st.status, this.fmtStepStatus(st.status))}
                                ${st.price !== null && st.price !== undefined ? `<span class="step-price">${fmtMoney(st.price)}</span>` : ''}
                              </div>
                              ${
                                st.description
                                  ? `<div class="step-descr"><span class="lbl">Описание:</span> ${escapeHtml(st.description)}</div>`
                                  : ''
                              }
                              ${
                                st.whatDid
                                  ? `<div class="step-descr"><span class="lbl">Что сделано:</span> ${escapeHtml(st.whatDid)}</div>`
                                  : ''
                              }
                              ${
                                st.howDid
                                  ? `<div class="step-descr"><span class="lbl">Как сделано:</span> ${escapeHtml(st.howDid)}</div>`
                                  : ''
                              }
                              ${
                                st.doneAt
                                  ? `<div class="step-descr"><span class="lbl">Закрыт:</span> ${fmtDate(st.doneAt)}${st.doneByName ? ' · ' + escapeHtml(st.doneByName) : ''}</div>`
                                  : ''
                              }
                              ${
                                st.substeps.length > 0
                                  ? `<ul class="substeps">${st.substeps
                                      .map(
                                        (ss) =>
                                          `<li class="${ss.isDone ? 'done' : ''}">${ss.isDone ? '✓ ' : '· '}${escapeHtml(ss.text)}${ss.doneAt ? ` <span class="muted">(${fmtDate(ss.doneAt)})</span>` : ''}</li>`,
                                      )
                                      .join('')}</ul>`
                                  : ''
                              }
                              ${
                                st.questions.length > 0
                                  ? `<div class="questions">
                                      <div class="lbl">Вопросы / ответы:</div>
                                      ${st.questions
                                        .map(
                                          (q) => `<div class="qa">
                                            <div class="q"><b>${escapeHtml(q.authorName)} → ${escapeHtml(q.addresseeName)}:</b> ${escapeHtml(q.text)}</div>
                                            ${q.answer ? `<div class="a"><b>Ответ:</b> ${escapeHtml(q.answer)}${q.answeredAt ? ` <span class="muted">(${fmtDate(q.answeredAt)})</span>` : ''}</div>` : `<div class="a muted">— нет ответа (${escapeHtml(q.status)})</div>`}
                                          </div>`,
                                        )
                                        .join('')}
                                    </div>`
                                  : ''
                              }
                              ${
                                st.photos.length > 0
                                  ? `<div class="photos">
                                      ${st.photos
                                        .map((ph) =>
                                          ph.dataUrl
                                            ? `<figure><img src="${ph.dataUrl}" alt="step photo"/></figure>`
                                            : `<figure class="photo-missing"><span>фото недоступно</span><code>s3://${escapeHtml(ph.fileKey)}</code></figure>`,
                                        )
                                        .join('')}
                                    </div>`
                                  : ''
                              }
                            </div>`,
                        )
                        .join('')}
                    `
                    : '<p class="muted">Шагов нет.</p>'
                }
              </article>`,
                )
                .join('')
        }
      </section>`;

    const materialsSection = `
      <section class="page-break">
        <h2>Материалы (${d.materials.length})</h2>
        ${
          d.materials.length === 0
            ? `<p class="muted">Заявок на материалы нет.</p>`
            : d.materials
                .map(
                  (m) => `<article class="material">
                  <h4>${escapeHtml(m.title)} ${this.statusPill(m.status, this.fmtMaterialStatus(m.status))}</h4>
                  <div class="meta">
                    <span><b>Дата:</b> ${fmtDate(m.createdAt)}</span>
                    <span><b>Этап:</b> ${escapeHtml(m.stageName)}</span>
                    <span><b>Получатель:</b> ${escapeHtml(this.fmtMaterialRecipient(m.recipient))}</span>
                    ${m.deliveredAt ? `<span><b>Поставка:</b> ${fmtDate(m.deliveredAt)}</span>` : ''}
                  </div>
                  ${m.comment ? `<div class="muted">«${escapeHtml(m.comment)}»</div>` : ''}
                  ${
                    m.items.length > 0
                      ? `<table class="grid items">
                          <thead><tr><th>Позиция</th><th class="num">Кол-во</th><th>Ед.</th><th class="num">Цена</th><th class="num">Сумма</th><th>Куплено</th></tr></thead>
                          <tbody>
                          ${m.items
                            .map(
                              (it) => `<tr>
                                <td>${escapeHtml(it.name)}</td>
                                <td class="num">${escapeHtml(it.qty)}</td>
                                <td>${escapeHtml(it.unit ?? '—')}</td>
                                <td class="num">${fmtMoney(it.pricePerUnit)}</td>
                                <td class="num">${fmtMoney(it.totalPrice)}</td>
                                <td>${it.isBought ? '✓' : '—'}</td>
                              </tr>`,
                            )
                            .join('')}
                          </tbody>
                        </table>`
                      : ''
                  }
                </article>`,
                )
                .join('')
        }
        ${
          d.selfPurchases.length > 0
            ? `<h3>Самозакуп (${d.selfPurchases.length})</h3>
              <table class="grid">
                <thead><tr><th>Дата</th><th>Кто</th><th>Кому</th><th>Этап</th><th class="num">Сумма</th><th>Статус</th><th>Комментарий</th></tr></thead>
                <tbody>
                ${d.selfPurchases
                  .map(
                    (s) => `<tr>
                      <td class="nowrap">${fmtDate(s.createdAt)}</td>
                      <td>${escapeHtml(s.byName)} <span class="muted">(${escapeHtml(s.byRole)})</span></td>
                      <td>${escapeHtml(s.addresseeName)}</td>
                      <td>${escapeHtml(s.stageName)}</td>
                      <td class="num"><b>${fmtMoney(s.amount)}</b></td>
                      <td>${this.statusPill(s.status, this.fmtSelfpurchaseStatus(s.status))}</td>
                      <td>${s.comment ? escapeHtml(s.comment) : '—'}</td>
                    </tr>${
                      s.photoDataUrls.length > 0
                        ? `<tr class="receipt"><td colspan="7"><div class="photos compact">${s.photoDataUrls
                            .map(
                              (url) => `<figure><img src="${url}" alt="self-purchase"/></figure>`,
                            )
                            .join('')}</div></td></tr>`
                        : ''
                    }`,
                  )
                  .join('')}
                </tbody>
              </table>`
            : ''
        }
      </section>`;

    const toolsSection = `
      <section class="page-break">
        <h2>Инструменты (${d.tools.length})</h2>
        ${
          d.tools.length === 0
            ? `<p class="muted">Передач инструмента нет.</p>`
            : `<table class="grid">
                <thead><tr>
                  <th>Дата выдачи</th><th>Инструмент</th><th>S/N</th>
                  <th class="num">Кол-во</th><th>Кому</th><th>От кого</th><th>Этап</th><th>Статус</th>
                </tr></thead>
                <tbody>
                ${d.tools
                  .map(
                    (t) => `<tr>
                      <td class="nowrap">${fmtDate(t.issuedAt)}</td>
                      <td>${escapeHtml(t.toolName)}</td>
                      <td>${escapeHtml(t.serial ?? '—')}</td>
                      <td class="num">${t.qty}</td>
                      <td>${escapeHtml(t.toName)}</td>
                      <td>${escapeHtml(t.issuedByName)}</td>
                      <td>${escapeHtml(t.stageName)}</td>
                      <td>${this.statusPill(t.status, this.fmtToolStatus(t.status))}</td>
                    </tr>`,
                  )
                  .join('')}
                </tbody>
              </table>`
        }
      </section>`;

    const documentsSection = `
      <section class="page-break">
        <h2>Документы (${d.documents.length})</h2>
        ${
          d.documents.length === 0
            ? `<p class="muted">Документов нет.</p>`
            : `<table class="grid">
                <thead><tr><th>Название</th><th>Категория</th><th>Тип</th><th class="num">Размер</th><th>Загрузил</th><th>Дата</th></tr></thead>
                <tbody>
                ${d.documents
                  .map(
                    (doc) => `<tr>
                      <td>${doc.downloadUrl ? `<a href="${doc.downloadUrl}">${escapeHtml(doc.title)}</a>` : escapeHtml(doc.title)}<br/><code class="muted">s3://${escapeHtml(doc.fileKey)}</code></td>
                      <td>${escapeHtml(this.fmtDocCategory(doc.category))}</td>
                      <td>${escapeHtml(doc.mimeType)}</td>
                      <td class="num">${(doc.sizeBytes / 1024).toFixed(0)} KB</td>
                      <td>${escapeHtml(doc.uploadedByName)}</td>
                      <td class="nowrap">${fmtDate(doc.createdAt)}</td>
                    </tr>`,
                  )
                  .join('')}
                </tbody>
              </table>`
        }
      </section>`;

    const feedSection = `
      <section class="page-break">
        <h2>Лента событий (${d.feed.length})</h2>
        ${
          d.feed.length === 0
            ? `<p class="muted">Событий нет.</p>`
            : `<table class="grid feed">
                <thead><tr><th>Время (UTC)</th><th>Событие</th><th>Автор</th><th>Этап</th><th>Описание</th></tr></thead>
                <tbody>
                ${d.feed
                  .map(
                    (f) => `<tr>
                      <td class="nowrap">${fmtDateTime(f.createdAt)}</td>
                      <td>${escapeHtml(f.kind)}</td>
                      <td>${escapeHtml(f.actorName)}</td>
                      <td>${f.stageName ? escapeHtml(f.stageName) : '—'}</td>
                      <td>${escapeHtml(f.description)}</td>
                    </tr>`,
                  )
                  .join('')}
                </tbody>
              </table>`
        }
      </section>`;

    return `<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8"/>
  <title>Отчёт по проекту — ${escapeHtml(d.project.title)}</title>
  <style>${this.css()}</style>
</head>
<body>
  ${cover}
  ${budgetSection}
  ${paymentsSection}
  ${teamSection}
  ${stagesSection}
  ${materialsSection}
  ${toolsSection}
  ${documentsSection}
  ${feedSection}
  <footer class="report-footer">
    Создано в Repair Control · ${fmtDateTime(d.generatedAt)} · документ носит юридическую силу как фиксация работ по проекту
  </footer>
</body></html>`;
  }

  private css(): string {
    return `
      @page { size: A4; margin: 18mm 14mm 18mm 14mm; }
      * { box-sizing: border-box; }
      body { font-family: 'Manrope', 'Helvetica Neue', Arial, sans-serif; color:#0D1229; font-size:11pt; line-height:1.45; margin:0; }
      h1 { font-size:28pt; margin:0 0 12px; letter-spacing:-0.02em; }
      h2 { font-size:18pt; margin:24px 0 12px; padding-bottom:6px; border-bottom:2px solid #0D1229; }
      h3 { font-size:14pt; margin:18px 0 8px; }
      h4 { font-size:12pt; margin:14px 0 6px; color:#1F2640; }
      a { color:#4259E5; text-decoration:none; word-break:break-all; }
      code { font-family:'JetBrains Mono', 'Menlo', monospace; font-size:9pt; color:#556; }
      .muted { color:#6E7AAA; }
      .nowrap { white-space: nowrap; }
      .num { text-align: right; font-variant-numeric: tabular-nums; }
      .page-break { page-break-before: always; }
      .branding { display:flex; align-items:baseline; gap:12px; margin-bottom:18px; }
      .brand-mark { font-weight:800; font-size:14pt; letter-spacing:0.04em; color:#0D1229; padding:4px 10px; border:1.5px solid #0D1229; border-radius:6px; }
      .brand-sub { color:#6E7AAA; font-size:10pt; }
      .cover { padding-bottom:24px; border-bottom:1px solid #E3E8F1; }
      .cover-meta { display:grid; grid-template-columns:1fr 1fr; gap:8px 24px; margin-top:8px; }
      .cover-meta > div { display:flex; padding:6px 0; border-bottom:1px solid #EEF2FF; }
      .lbl { font-weight:600; color:#6E7AAA; min-width:140px; }
      .val { color:#0D1229; }
      .dot { display:inline-block; width:10px; height:10px; border-radius:50%; vertical-align:middle; margin-right:6px; }
      .cover-descr { margin-top:14px; padding:12px; background:#F7F8FC; border-radius:8px; }
      .cover-stamp { margin-top:18px; font-size:9.5pt; color:#6E7AAA; padding-top:12px; border-top:1px dashed #E3E8F1; }
      table { width:100%; border-collapse:collapse; font-size:10pt; }
      table.kv th { text-align:left; width:160px; color:#6E7AAA; padding:6px 8px; vertical-align:top; border-bottom:1px solid #EEF2FF; }
      table.kv td { padding:6px 8px; border-bottom:1px solid #EEF2FF; }
      table.kv tr.total th, table.kv tr.total td { font-weight:700; font-size:11pt; background:#F7F8FC; }
      table.kv.compact th { width:130px; }
      table.grid th { background:#EEF2FF; color:#1F2640; text-align:left; padding:6px 8px; border-bottom:2px solid #D6DDF0; font-weight:700; }
      table.grid td { padding:5px 8px; border-bottom:1px solid #E3E8F1; vertical-align:top; }
      table.grid tr:nth-child(even) td { background:#FBFCFE; }
      table.grid.feed td { font-size:9.5pt; }
      tr.receipt td { background:#FFFCF4 !important; padding:6px 12px; }
      .receipt-block { display:flex; align-items:center; gap:10px; }
      .receipt-block img { max-height:140px; max-width:240px; border-radius:6px; border:1px solid #E3E8F1; }
      .pill { display:inline-block; padding:2px 8px; border-radius:10px; font-size:9pt; font-weight:600; white-space:nowrap; }
      .pill.pending { background:#FFF3E0; color:#B6580F; }
      .pill.pending_approval { background:#FFF3E0; color:#B6580F; }
      .pill.in_progress, .pill.active, .pill.confirmed, .pill.done, .pill.returned, .pill.approved, .pill.delivered { background:#E6F8F0; color:#0F8A66; }
      .pill.rejected, .pill.failed, .pill.disputed, .pill.cancelled, .pill.expired { background:#FCE9EA; color:#B22A2F; }
      .pill.paused, .pill.review, .pill.resolved, .pill.queued, .pill.running { background:#EEF2FF; color:#2D3D8F; }
      .pill.issued, .pill.return_requested, .pill.bought, .pill.partially_bought, .pill.finalized, .pill.forwarded { background:#EEF2FF; color:#2D3D8F; }
      .stage { margin-top:18px; padding-bottom:16px; border-bottom:1px solid #E3E8F1; }
      .step { margin:10px 0; padding:10px 12px; background:#FBFCFE; border-left:3px solid #4259E5; border-radius:0 6px 6px 0; page-break-inside: avoid; }
      .step-header { display:flex; align-items:baseline; gap:8px; flex-wrap:wrap; }
      .step-no { font-weight:700; color:#6E7AAA; }
      .step-title { font-weight:700; flex-grow:1; }
      .step-price { color:#0F8A66; font-weight:600; }
      .step-descr { margin-top:4px; font-size:10pt; }
      .substeps { margin:6px 0 0 0; padding-left:14px; list-style:none; }
      .substeps li { padding:2px 0; font-size:10pt; }
      .substeps li.done { color:#0F8A66; }
      .questions { margin-top:8px; padding:8px 10px; background:#FFF8E1; border-radius:6px; font-size:10pt; }
      .qa { margin-top:4px; }
      .qa .q { color:#1F2640; }
      .qa .a { color:#0F8A66; margin-top:2px; }
      .photos { margin-top:8px; display:flex; flex-wrap:wrap; gap:6px; }
      .photos.compact { gap:4px; }
      .photos figure { margin:0; }
      .photos img { max-height:200px; max-width:220px; border-radius:6px; border:1px solid #E3E8F1; }
      .photo-missing { padding:18px; border:1px dashed #C9D0E3; border-radius:6px; color:#6E7AAA; font-size:9pt; text-align:center; }
      .material { padding:10px 0; border-bottom:1px solid #E3E8F1; }
      .material .meta { display:flex; flex-wrap:wrap; gap:14px; color:#1F2640; font-size:10pt; margin:4px 0; }
      .items td { font-size:9.5pt; }
      .report-footer { margin-top:32px; padding-top:14px; border-top:1px solid #E3E8F1; color:#6E7AAA; font-size:9pt; text-align:center; }
    `;
  }

  private statusPill(status: string, label: string): string {
    const key = (status || '').toLowerCase().replace(/[^a-z_]/g, '_');
    return `<span class="pill ${escapeHtml(key)}">${escapeHtml(label)}</span>`;
  }

  // -------------------- RENDER --------------------

  async renderPdf(html: string): Promise<Buffer> {
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const chromium = require('@sparticuz/chromium');
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const puppeteer = require('puppeteer-core');
      const browser = await puppeteer.launch({
        args: chromium.args,
        defaultViewport: chromium.defaultViewport,
        executablePath: await chromium.executablePath(),
        headless: true,
      });
      try {
        const page = await browser.newPage();
        await page.setContent(html, { waitUntil: 'networkidle0' });
        const buffer = (await page.pdf({
          format: 'A4',
          printBackground: true,
          displayHeaderFooter: true,
          headerTemplate:
            '<div style="font-family:Manrope,Arial,sans-serif;font-size:8pt;color:#6E7AAA;padding:0 14mm;width:100%;display:flex;justify-content:space-between;"><span>Repair Control · Отчёт по проекту</span><span class="date"></span></div>',
          footerTemplate:
            '<div style="font-family:Manrope,Arial,sans-serif;font-size:8pt;color:#6E7AAA;padding:0 14mm;width:100%;display:flex;justify-content:space-between;"><span>Создано в Repair Control</span><span>Стр. <span class="pageNumber"></span> / <span class="totalPages"></span></span></div>',
          margin: { top: '20mm', bottom: '20mm', left: '14mm', right: '14mm' },
        })) as Buffer;
        return buffer;
      } finally {
        await browser.close();
      }
    } catch (e) {
      this.logger.warn(
        `puppeteer unavailable for project report, falling back to HTML buffer: ${(e as Error).message}`,
      );
      return Buffer.from(html, 'utf-8');
    }
  }

  private fallbackPlain(text: string): Buffer {
    return Buffer.from(text, 'utf-8');
  }

  // -------------------- HELPERS / VISIBILITY --------------------

  private async fetchAsDataUrl(fileKey: string, mimeType: string): Promise<string | null> {
    try {
      const buf = await this.files.getObjectBuffer(fileKey);
      if (buf.length > ProjectReportPdfService.MAX_PHOTO_BYTES) {
        return null; // слишком большое — лучше не встраивать (защита от ОЗУ)
      }
      const safeMime = mimeType.startsWith('image/') ? mimeType : 'image/jpeg';
      return `data:${safeMime};base64,${buf.toString('base64')}`;
    } catch (e) {
      this.logger.warn(`skip photo ${fileKey}: ${(e as Error).message}`);
      return null;
    }
  }

  private computeVisibleStageIds(viewer: ReportViewer): Set<string> | null {
    const role = viewer.membershipRole;
    if (viewer.isOwner || role === 'representative' || role === 'customer') {
      return null;
    }
    const ids = new Set<string>();
    viewer.foremanStageIds.forEach((id) => ids.add(id));
    viewer.assignedStageIds.forEach((id) => ids.add(id));
    return ids;
  }

  private filterTeam<T extends { userId: string; role: string; invitedById: string | null }>(
    all: T[],
    viewer: ReportViewer,
    visibleStages: Array<{ id: string; foremanIds: string[]; masterId: string | null }>,
  ): T[] {
    const role = viewer.membershipRole;
    if (viewer.isOwner) {
      return all.filter((m) => {
        if (m.role !== 'master') return true;
        return m.invitedById === viewer.userId || m.invitedById === null;
      });
    }
    if (role === 'representative' || role === 'customer') return all;
    if (role === 'foreman') {
      const myStageIds = new Set(viewer.foremanStageIds);
      const myMasterIds = new Set<string>();
      for (const s of visibleStages) {
        if (myStageIds.has(s.id) && s.masterId) myMasterIds.add(s.masterId);
      }
      return all.filter((m) => {
        if (m.userId === viewer.userId) return true;
        if (m.role === 'customer' || m.role === 'representative') return true;
        if (m.role === 'master') return myMasterIds.has(m.userId);
        return false;
      });
    }
    if (role === 'master') {
      const myStageIds = new Set([...viewer.assignedStageIds, ...viewer.foremanStageIds]);
      const visibleUserIds = new Set<string>();
      visibleUserIds.add(viewer.userId);
      for (const s of visibleStages) {
        if (myStageIds.has(s.id)) {
          s.foremanIds.forEach((id) => visibleUserIds.add(id));
          if (s.masterId) visibleUserIds.add(s.masterId);
        }
      }
      return all.filter((m) => {
        if (m.role === 'customer' || m.role === 'representative') return true;
        return visibleUserIds.has(m.userId);
      });
    }
    return [];
  }

  private computeHiddenUserIds(
    all: Array<{ userId: string; role: string; invitedById: string | null }>,
    viewer: ReportViewer,
  ): Set<string> {
    if (!viewer.isOwner) return new Set();
    const hidden = new Set<string>();
    for (const m of all) {
      if (m.role === 'master' && m.invitedById && m.invitedById !== viewer.userId) {
        hidden.add(m.userId);
      }
    }
    return hidden;
  }

  // -------------------- LOADERS --------------------

  private async loadPayments(
    projectId: string,
    viewer: ReportViewer,
    visibleStageIds: string[],
  ): Promise<
    Array<{
      id: string;
      stageId: string | null;
      kind: string;
      amount: bigint;
      fromUserId: string;
      toUserId: string;
      photoKey: string | null;
      comment: string | null;
      createdAt: Date;
    }>
  > {
    const role = viewer.membershipRole;
    const select = {
      id: true,
      stageId: true,
      kind: true,
      amount: true,
      fromUserId: true,
      toUserId: true,
      photoKey: true,
      comment: true,
      createdAt: true,
    } as const;

    if (viewer.canSeeAllPayments) {
      return this.prisma.payment.findMany({
        where: { projectId },
        select,
        orderBy: { createdAt: 'asc' },
      });
    }
    if (role === 'foreman') {
      return this.prisma.payment.findMany({
        where: {
          projectId,
          OR: [
            { stageId: { in: visibleStageIds } },
            { fromUserId: viewer.userId },
            { toUserId: viewer.userId },
          ],
        },
        select,
        orderBy: { createdAt: 'asc' },
      });
    }
    if (role === 'master') {
      return this.prisma.payment.findMany({
        where: {
          projectId,
          OR: [{ fromUserId: viewer.userId }, { toUserId: viewer.userId }],
        },
        select,
        orderBy: { createdAt: 'asc' },
      });
    }
    return [];
  }

  private async loadMaterials(
    projectId: string,
    viewer: ReportViewer,
    visibleStageIds: string[],
  ): Promise<
    Array<{
      id: string;
      stageId: string | null;
      title: string;
      status: string;
      recipient: string;
      comment: string | null;
      createdAt: Date;
      deliveredAt: Date | null;
      items: Array<{
        name: string;
        qty: unknown;
        unit: string | null;
        pricePerUnit: bigint | null;
        totalPrice: bigint | null;
        isBought: boolean;
      }>;
    }>
  > {
    const visibleSet = this.computeVisibleStageIds(viewer);
    const rows = await this.prisma.materialRequest.findMany({
      where: {
        projectId,
        ...(visibleSet ? { OR: [{ stageId: null }, { stageId: { in: visibleStageIds } }] } : {}),
      },
      include: { items: { orderBy: { createdAt: 'asc' } } },
      orderBy: { createdAt: 'asc' },
    });
    return rows as unknown as Array<{
      id: string;
      stageId: string | null;
      title: string;
      status: string;
      recipient: string;
      comment: string | null;
      createdAt: Date;
      deliveredAt: Date | null;
      items: Array<{
        name: string;
        qty: unknown;
        unit: string | null;
        pricePerUnit: bigint | null;
        totalPrice: bigint | null;
        isBought: boolean;
      }>;
    }>;
  }

  private async loadSelfPurchases(
    projectId: string,
    viewer: ReportViewer,
    visibleStageIds: string[],
  ): Promise<
    Array<{
      id: string;
      stageId: string | null;
      byUserId: string;
      byRole: string;
      addresseeId: string;
      amount: bigint;
      status: string;
      comment: string | null;
      photoKeys: string[];
      createdAt: Date;
    }>
  > {
    const select = {
      id: true,
      stageId: true,
      byUserId: true,
      byRole: true,
      addresseeId: true,
      amount: true,
      status: true,
      comment: true,
      photoKeys: true,
      createdAt: true,
    } as const;
    const role = viewer.membershipRole;
    if (viewer.canSeeAllPayments || viewer.isOwner) {
      return this.prisma.selfPurchase.findMany({
        where: { projectId },
        select,
        orderBy: { createdAt: 'asc' },
      });
    }
    if (role === 'foreman') {
      return this.prisma.selfPurchase.findMany({
        where: {
          projectId,
          OR: [
            { stageId: { in: visibleStageIds } },
            { byUserId: viewer.userId },
            { addresseeId: viewer.userId },
          ],
        },
        select,
        orderBy: { createdAt: 'asc' },
      });
    }
    if (role === 'master') {
      return this.prisma.selfPurchase.findMany({
        where: {
          projectId,
          OR: [{ byUserId: viewer.userId }, { addresseeId: viewer.userId }],
        },
        select,
        orderBy: { createdAt: 'asc' },
      });
    }
    return [];
  }

  /**
   * Self-custody модель (2026-05-12): инструменты больше не имеют ToolIssuance.
   * В PDF-отчёт идут события передач (ToolCustodyEvent) — для совместимости
   * со сложившимся форматом таблицы возвращаем shape, эквивалентный старому
   * ToolIssuance-row'у: каждое событие = одна строка «у кого / откуда / когда».
   */
  private async loadTools(
    projectId: string,
    _viewer: ReportViewer,
    _visibleStageIds: string[],
  ): Promise<
    Array<{
      id: string;
      toolItemId: string;
      stageId: string | null;
      toUserId: string;
      issuedById: string;
      qty: number;
      status: string;
      issuedAt: Date;
      confirmedAt: Date | null;
      returnedAt: Date | null;
    }>
  > {
    const events = await this.prisma.toolCustodyEvent.findMany({
      where: { projectId },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        toolItemId: true,
        holderId: true,
        previousHolderId: true,
        createdAt: true,
      },
    });
    return events.map((e) => ({
      id: e.id,
      toolItemId: e.toolItemId,
      stageId: null,
      toUserId: e.holderId,
      issuedById: e.previousHolderId ?? e.holderId,
      qty: 1,
      status: 'confirmed',
      issuedAt: e.createdAt,
      confirmedAt: e.createdAt,
      returnedAt: null,
    }));
  }

  private async loadFeed(
    projectId: string,
    viewer: ReportViewer,
    visibleStageIds: Set<string>,
  ): Promise<
    Array<{
      kind: string;
      actorId: string | null;
      stageId: string | null;
      payload: unknown;
      createdAt: Date;
    }>
  > {
    const role = viewer.membershipRole;
    let stageFilter: Record<string, unknown> = {};
    if (!viewer.isOwner && role !== 'representative' && role !== 'customer') {
      const stages = [...visibleStageIds];
      stageFilter = { OR: [{ stageId: null }, { stageId: { in: stages } }] };
    }
    return this.prisma.feedEvent.findMany({
      where: { projectId, ...stageFilter },
      orderBy: { createdAt: 'asc' },
      take: 2000,
      select: {
        kind: true,
        actorId: true,
        stageId: true,
        payload: true,
        createdAt: true,
      },
    });
  }

  // -------------------- FORMATTERS --------------------

  private describeFeedEvent(kind: string, payload: Record<string, unknown>): string {
    const p = payload ?? {};
    const t = (k: string): string => (p[k] !== undefined ? String(p[k]) : '');
    switch (kind) {
      case 'project_created':
        return 'Проект создан';
      case 'project_archived':
        return 'Проект архивирован';
      case 'project_restored':
        return 'Проект восстановлен';
      case 'stage_created':
        return `Создан этап ${t('title')}`.trim();
      case 'stage_started':
        return 'Этап запущен';
      case 'stage_paused':
        return `Этап поставлен на паузу${t('reason') ? ` (${t('reason')})` : ''}`;
      case 'stage_resumed':
        return 'Этап снят с паузы';
      case 'stage_sent_to_review':
        return 'Этап отправлен на приёмку';
      case 'stage_accepted':
        return 'Этап принят заказчиком';
      case 'stage_rejected_by_customer':
        return `Этап отклонён заказчиком${t('comment') ? `: ${t('comment')}` : ''}`;
      case 'step_created':
        return `Создан шаг ${t('title')}`.trim();
      case 'step_completed':
        return `Шаг закрыт${t('title') ? `: ${t('title')}` : ''}`;
      case 'step_uncompleted':
        return 'Шаг возвращён в работу';
      case 'photo_attached':
        return 'Прикреплено фото к шагу';
      case 'approval_requested':
        return `Запрошено согласование${t('scope') ? ` (${t('scope')})` : ''}`;
      case 'approval_approved':
        return 'Согласование одобрено';
      case 'approval_rejected':
        return `Согласование отклонено${t('comment') ? `: ${t('comment')}` : ''}`;
      case 'payment_created':
        return `Платёж создан${t('amount') ? `: ${t('amount')} коп.` : ''}`;
      case 'payment_distributed':
        return 'Аванс распределён';
      case 'material_request_created':
        return `Заявка на материалы${t('title') ? `: ${t('title')}` : ''}`;
      case 'material_request_approved':
        return 'Заявка на материалы согласована';
      case 'material_delivered':
        return 'Материалы доставлены';
      case 'selfpurchase_created':
        return 'Создан самозакуп';
      case 'selfpurchase_approved':
        return 'Самозакуп одобрен';
      case 'selfpurchase_rejected':
        return 'Самозакуп отклонён';
      case 'tool_added_to_project':
        return 'Инструмент добавлен в проект';
      case 'tool_removed_from_project':
        return 'Инструмент убран из проекта';
      case 'tool_custody_changed':
        return 'Передача инструмента';
      case 'document_uploaded':
        return `Загружен документ${t('title') ? `: ${t('title')}` : ''}`;
      case 'membership_added':
        return 'В команду добавлен участник';
      case 'membership_removed':
        return 'Участник удалён из команды';
      case 'budget_updated':
        return 'Изменён бюджет';
      case 'deadline_changed':
        return 'Изменён дедлайн';
      case 'export_requested':
        return 'Запрошен экспорт';
      case 'export_completed':
        return 'Экспорт сформирован';
      case 'chat_message_sent':
        return 'Сообщение в чате';
      default:
        return kind;
    }
  }

  private fmtProjectStatus(s: string): string {
    if (s === 'archived') return 'архивный';
    if (s === 'completed') return 'завершённый';
    return 'активный';
  }
  private fmtStageStatus(s: string): string {
    return (
      (
        {
          pending: 'Ожидает',
          active: 'В работе',
          paused: 'На паузе',
          review: 'На проверке',
          done: 'Завершён',
          rejected: 'Отклонён',
        } as Record<string, string>
      )[s] ?? s
    );
  }
  private fmtStepStatus(s: string): string {
    return (
      (
        {
          pending: 'ожидает',
          in_progress: 'в работе',
          done: 'выполнен',
          pending_approval: 'на согласовании',
          rejected: 'отклонён',
        } as Record<string, string>
      )[s] ?? s
    );
  }
  private fmtRole(r: string): string {
    return (
      (
        {
          customer: 'заказчик',
          representative: 'представитель',
          foreman: 'бригадир',
          master: 'мастер',
          owner: 'владелец',
          member: 'участник',
        } as Record<string, string>
      )[r] ?? r
    );
  }
  private fmtPaymentKind(k: string): string {
    return (
      (
        {
          advance: 'аванс',
          distribution: 'распределение',
          correction: 'корректировка',
          final: 'окончательный расчёт',
          selfpurchase: 'самозакуп',
          extra_work: 'доп. работа',
        } as Record<string, string>
      )[k] ?? k
    );
  }
  private fmtDocCategory(c: string): string {
    return (
      (
        {
          contract: 'договор',
          act: 'акт',
          estimate: 'смета',
          warranty: 'гарантия',
          photo: 'фото',
          blueprint: 'чертёж',
          other: 'прочее',
        } as Record<string, string>
      )[c] ?? c
    );
  }
  private fmtMaterialStatus(s: string): string {
    return (
      (
        {
          pending_approval: 'на согласовании',
          approved: 'согласована',
          bought: 'куплено',
          partially_bought: 'частично куплено',
          finalized: 'закрыта',
          delivered: 'доставлено',
          disputed: 'оспорена',
          cancelled: 'отменена',
        } as Record<string, string>
      )[s] ?? s
    );
  }
  private fmtMaterialRecipient(r: string): string {
    return (
      (
        {
          foreman: 'бригадир',
          customer: 'заказчик',
        } as Record<string, string>
      )[r] ?? r
    );
  }
  private fmtSelfpurchaseStatus(s: string): string {
    return (
      (
        {
          pending: 'ожидает',
          approved: 'одобрен',
          rejected: 'отклонён',
          forwarded: 'переадресован',
        } as Record<string, string>
      )[s] ?? s
    );
  }
  private fmtToolStatus(s: string): string {
    return (
      (
        {
          issued: 'выдан',
          confirmed: 'подтверждён получателем',
          return_requested: 'запрошен возврат',
          returned: 'возвращён',
        } as Record<string, string>
      )[s] ?? s
    );
  }
}

function escapeHtml(s: string): string {
  if (s === null || s === undefined) return '';
  return String(s).replace(
    /[&<>"']/g,
    (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!,
  );
}
