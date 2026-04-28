import { Injectable } from '@nestjs/common';
import { Clock, ErrorCodes, NotFoundError, PrismaService } from '@app/common';
import { FeedService } from '../feed/feed.service';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly feed: FeedService,
  ) {}

  // ---------- FAQ ----------

  async listFaqSections() {
    return this.prisma.faqSection.findMany({
      orderBy: { orderIndex: 'asc' },
      include: { items: { orderBy: { orderIndex: 'asc' } } },
    });
  }

  async getFaqItem(id: string) {
    const item = await this.prisma.faqItem.findUnique({
      where: { id },
      include: { section: { select: { id: true, title: true } } },
    });
    if (!item) throw new NotFoundError(ErrorCodes.FAQ_ITEM_NOT_FOUND, 'faq item not found');
    return item;
  }

  async createFaqSection(actorUserId: string, title: string, orderIndex: number) {
    const s = await this.prisma.faqSection.create({ data: { title, orderIndex } });
    await this.feed.emit({
      kind: 'admin_faq_updated',
      actorId: actorUserId,
      payload: { action: 'section_created', sectionId: s.id },
    });
    return s;
  }

  async createFaqItem(
    actorUserId: string,
    sectionId: string,
    question: string,
    answer: string,
    orderIndex: number,
  ) {
    const sec = await this.prisma.faqSection.findUnique({ where: { id: sectionId } });
    if (!sec) throw new NotFoundError(ErrorCodes.FAQ_SECTION_NOT_FOUND, 'section not found');
    const it = await this.prisma.faqItem.create({
      data: { sectionId, question, answer, orderIndex },
    });
    await this.feed.emit({
      kind: 'admin_faq_updated',
      actorId: actorUserId,
      payload: { action: 'item_created', itemId: it.id, sectionId },
    });
    return it;
  }

  async updateFaqItem(
    actorUserId: string,
    id: string,
    data: { question?: string; answer?: string; orderIndex?: number },
  ) {
    const existing = await this.prisma.faqItem.findUnique({ where: { id } });
    if (!existing) throw new NotFoundError(ErrorCodes.FAQ_ITEM_NOT_FOUND, 'item not found');
    const updated = await this.prisma.faqItem.update({ where: { id }, data });
    await this.feed.emit({
      kind: 'admin_faq_updated',
      actorId: actorUserId,
      payload: { action: 'item_updated', itemId: id },
    });
    return updated;
  }

  async deleteFaqItem(actorUserId: string, id: string) {
    await this.prisma.faqItem.delete({ where: { id } });
    await this.feed.emit({
      kind: 'admin_faq_updated',
      actorId: actorUserId,
      payload: { action: 'item_deleted', itemId: id },
    });
  }

  // ---------- AppSettings ----------

  async listSettings() {
    return this.prisma.appSetting.findMany({ orderBy: { key: 'asc' } });
  }

  async getPublicSettings() {
    // Подмножество безопасных для всех ключей
    const keys = ['support_telegram_url', 'policy_version', 'tos_version'];
    const rows = await this.prisma.appSetting.findMany({ where: { key: { in: keys } } });
    const out: Record<string, string> = {};
    for (const k of keys) out[k] = rows.find((r) => r.key === k)?.value ?? this.defaultSetting(k);
    return out;
  }

  async putSetting(actorUserId: string, key: string, value: string) {
    const s = await this.prisma.appSetting.upsert({
      where: { key },
      create: { key, value, updatedBy: actorUserId },
      update: { value, updatedBy: actorUserId, updatedAt: this.clock.now() },
    });
    await this.feed.emit({
      kind: 'admin_settings_updated',
      actorId: actorUserId,
      payload: { key },
    });
    return s;
  }

  private defaultSetting(key: string): string {
    if (key === 'support_telegram_url')
      return process.env.SUPPORT_TELEGRAM_URL ?? 'https://t.me/repaircontrol_support';
    return '';
  }
}
