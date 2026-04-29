import { AccessContext, DomainAction, RepresentativeRights } from './rbac.types';

/**
 * Решение матрицы прав из ТЗ §1.5 (4 системные роли × 16 действий).
 *
 * Правила:
 * - admin: всё.
 * - customer: владеет проектом (ownerId === userId) — может всё в рамках своего проекта.
 * - representative: определяется RepresentativeRights, привязанными к Membership.
 * - contractor (foreman): управляет этапами/шагами; не редактирует бюджет; может создавать выплаты распределения.
 * - master: работает только по назначенным этапам; ограничен просмотром и отметкой своих шагов.
 */
export const canAccess = (action: DomainAction, ctx: AccessContext): boolean => {
  if (ctx.systemRole === 'admin') return true;

  switch (action) {
    case 'project.create':
      return ctx.systemRole === 'customer';

    case 'project.edit':
    case 'project.archive':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      return false;

    case 'project.invite_member':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canInviteMembers;
      return false;

    case 'stage.manage':
    case 'stage.start':
    case 'stage.pause':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.membershipRole === 'foreman') return true;
      return false;

    case 'step.manage':
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') {
        // Мастер может управлять шагом, только если он назначен на этап или на сам шаг (ТЗ §6.4)
        const isStageAssignee = (ctx.stageForemanIds ?? []).includes(ctx.userId);
        const isStepAssignee = (ctx.stepAssigneeIds ?? []).includes(ctx.userId);
        return isStageAssignee || isStepAssignee;
      }
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      return false;

    case 'step.add_substep':
      // подшаги могут добавлять все участники проекта (ТЗ §6.4)
      return !!ctx.membershipRole;

    case 'step.photo.upload':
      // Фото шага может прикрепить любой активный участник (customer/rep.canEditStages/foreman/master)
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return !!ctx.membershipRole;
      return false;

    case 'note.manage':
    case 'question.manage':
      // Любой участник проекта. Точечные ограничения (author-only / addressee-only) — внутри сервиса.
      return !!ctx.membershipRole;

    case 'methodology.read':
      // Методичка видна всем аутентифицированным (ТЗ §8 спринт 3 день 6).
      return true;

    case 'methodology.edit':
      // Только админ правит методичку. Admin обрабатывается в блоке выше → сюда не доходит.
      return false;

    case 'finance.payment.confirm':
      // Подтверждение — любой участник проекта; точечная проверка toUserId === actor — в сервисе.
      return !!ctx.membershipRole;

    case 'finance.payment.dispute':
      // Спор может открыть любой участник; точечная проверка fromUserId|toUserId — в сервисе.
      return !!ctx.membershipRole;

    case 'finance.payment.resolve':
      // Резолвит спор — customer-owner или representative.canApprove.
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canApprove;
      return false;

    case 'finance.budget.view':
      // Бюджет видят customer-owner, representative.canSeeBudget, foreman и master — объём по RBAC matrix.
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canSeeBudget;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;

    case 'material.finalize':
      // Финализируют бригадир/заказчик. Master не может.
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canManageMaterials;
      if (ctx.membershipRole === 'foreman') return true;
      return false;

    case 'approval.request':
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;

    case 'approval.list':
      // Список согласований проекта видят все участники.
      return !!ctx.membershipRole;

    case 'approval.decide':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canApprove;
      if (ctx.membershipRole === 'foreman') return true;
      return false;

    case 'finance.budget.edit':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      return false;

    case 'finance.payment.create':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canCreatePayments;
      if (ctx.membershipRole === 'foreman') return true; // распределение аванса
      return false;

    case 'materials.manage':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canManageMaterials;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;

    case 'tools.manage':
      // заказчик инструменты не видит (ТЗ §1.4) — явный return false
      if (ctx.membershipRole === 'customer') return false;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canManageTools;
      return false;

    case 'tools.issue':
      // Инструмент выдаёт только бригадир-владелец (ownerId совпадает в сервисе).
      return ctx.membershipRole === 'foreman';

    case 'tools.return':
      // Возврат: мастер инициирует, бригадир подтверждает. Customer не видит (ТЗ §1.4).
      if (ctx.membershipRole === 'customer') return false;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;

    case 'selfpurchase.create':
      // Самозакуп создают бригадир/мастер (gaps §4.3).
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;

    case 'selfpurchase.confirm':
      // Адресат (customer-owner для byRole=foreman, foreman для byRole=master) —
      // точечная проверка addresseeId === actorUserId в сервисе.
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canApprove;
      if (ctx.membershipRole === 'foreman') return true;
      return false;

    case 'chat.read': {
      // Чат видят участники проекта/этапа. Customer видит project-чат всегда,
      // stage/personal — только если явно добавлен в participants (и чат не закрыт visibleToCustomer=false)
      if (!ctx.membershipRole) return false;
      // Если подгружен chat-контекст — проверяем участие
      if (ctx.chatIsParticipant !== undefined) {
        if (ctx.chatIsActiveParticipant) return true;
        // customer может смотреть чат этапа если foreman открыл его
        if (
          ctx.systemRole === 'customer' &&
          ctx.projectOwnerId === ctx.userId &&
          (ctx.chatType === 'stage' || ctx.chatType === 'group') &&
          ctx.chatVisibleToCustomer
        ) {
          return true;
        }
        return false;
      }
      return true;
    }

    case 'chat.write': {
      // Писать может только active-participant. Если customer получил visibility — он всё равно read-only.
      if (!ctx.membershipRole) return false;
      if (ctx.chatIsActiveParticipant) return true;
      return false;
    }

    case 'chat.create_personal': {
      // Любой active member проекта может инициировать personal-чат (ТЗ §10 + цитата клиента про подрядчиков).
      // Запрет самому-себе валидируется в сервисе.
      return !!ctx.membershipRole;
    }

    case 'chat.create_group': {
      // Group-чат может создать owner / rep.canInviteMembers / foreman.
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canInviteMembers;
      if (ctx.membershipRole === 'foreman') return true;
      return false;
    }

    case 'chat.toggle_customer_visibility': {
      // Только foreman-создатель чата может включить/выключить visibility для customer (цитата клиента).
      if (ctx.membershipRole !== 'foreman') return false;
      return ctx.chatCreatedById === ctx.userId;
    }

    case 'chat.moderate': {
      // Модерация (удаление сообщения, удаление участника) — owner проекта или creator чата.
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      return ctx.chatCreatedById === ctx.userId;
    }

    case 'document.read': {
      // Любой участник проекта видит документы проекта/этапа (ТЗ §11, цитата клиента про общую папку).
      return !!ctx.membershipRole;
    }

    case 'document.write': {
      // Загружают и редактируют: owner / rep.canEditStages / foreman / master (на своих этапах).
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;
    }

    case 'document.delete': {
      // Удалить — автор документа, owner проекта, rep.canEditStages, либо admin.
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.documentUploadedById && ctx.documentUploadedById === ctx.userId) return true;
      return false;
    }

    case 'feed.export': {
      // Экспорт ленты/архива — owner проекта или rep.canSeeBudget (содержит финансы, materials).
      // Foreman-у даём feed_pdf, но НЕ project_zip (выбор kind проверяется в сервисе).
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canSeeBudget;
      if (ctx.membershipRole === 'foreman') return true;
      return false;
    }

    case 'notification.settings.self': {
      // Свои настройки уведомлений может менять любой аутентифицированный.
      return true;
    }

    case 'feedback.create': {
      // Обратная связь — любой аутентифицированный.
      return true;
    }

    case 'admin.templates.manage':
    case 'admin.faq.manage':
    case 'admin.feedback.read':
    case 'admin.feedback.reply':
    case 'admin.settings.manage':
    case 'admin.notifications.inspect':
    case 'admin.users.list':
    case 'admin.users.detail':
    case 'admin.users.ban':
    case 'admin.users.reset_password':
    case 'admin.users.force_logout':
    case 'admin.users.manage_roles':
    case 'admin.projects.list_all':
    case 'admin.projects.force_archive':
    case 'admin.legal.read_admin':
    case 'admin.legal.manage':
    case 'admin.legal_publications.manage':
    case 'admin.knowledge.manage':
    case 'admin.broadcast.send':
    case 'admin.broadcast.list':
    case 'admin.audit.read':
    case 'admin.stats.read': {
      // Все admin.* — только системная роль admin (ветка выше admin→true, сюда не доходит).
      return false;
    }

    case 'legal.accept': {
      // Любой аутентифицированный пользователь может принять версии политики.
      return true;
    }

    case 'knowledge.read': {
      // База знаний доступна всем аутентифицированным (контент общий).
      return true;
    }

    default:
      return false;
  }
};

export const mergeRepresentativeRights = (
  base: RepresentativeRights | undefined,
  override: Partial<RepresentativeRights> | undefined,
): RepresentativeRights => ({
  canEditStages: false,
  canApprove: false,
  canSeeBudget: false,
  canAddRepresentative: false,
  canCreatePayments: false,
  canManageMaterials: false,
  canManageTools: false,
  canInviteMembers: false,
  ...(base ?? {}),
  ...(override ?? {}),
});
