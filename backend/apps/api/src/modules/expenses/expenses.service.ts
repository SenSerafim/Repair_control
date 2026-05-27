import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '@app/common';
import type { ExpenseCategoryLike } from './dto';

interface CreateInput {
  projectId: string;
  createdById: string;
  category: ExpenseCategoryLike;
  name: string;
  amount: number;
  stageId?: string;
  comment?: string;
  photoKey?: string;
}

/**
 * ТЗ NEWFIX §5: «расход» — операция без получателя (отличается от Payment),
 * необязательная привязка к этапу, с фото чека и категорией. Простой
 * CRUD-сервис без FSM и сложных пересчётов: бюджет проекта обновляется
 * на лету через aggregate в BudgetController.
 */
@Injectable()
export class ExpensesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(input: CreateInput) {
    if (input.stageId) {
      const stage = await this.prisma.stage.findUnique({
        where: { id: input.stageId },
        select: { projectId: true },
      });
      if (!stage) throw new NotFoundException('stage_not_found');
      if (stage.projectId !== input.projectId) {
        throw new BadRequestException('stage_belongs_to_other_project');
      }
    }
    return this.prisma.expense.create({
      data: {
        projectId: input.projectId,
        createdById: input.createdById,
        category: input.category,
        name: input.name,
        amount: BigInt(input.amount),
        stageId: input.stageId,
        comment: input.comment,
        photoKey: input.photoKey,
      },
    });
  }

  async listForProject(
    projectId: string,
    opts?: { stageId?: string; category?: ExpenseCategoryLike },
  ) {
    return this.prisma.expense.findMany({
      where: {
        projectId,
        ...(opts?.stageId !== undefined ? { stageId: opts.stageId } : {}),
        ...(opts?.category !== undefined ? { category: opts.category } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async totalForProject(projectId: string) {
    const agg = await this.prisma.expense.aggregate({
      where: { projectId },
      _sum: { amount: true },
    });
    return Number(agg._sum.amount ?? 0n);
  }

  async totalForStage(stageId: string) {
    const agg = await this.prisma.expense.aggregate({
      where: { stageId },
      _sum: { amount: true },
    });
    return Number(agg._sum.amount ?? 0n);
  }
}
