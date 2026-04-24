import { PrismaClient, TemplateKind } from '@prisma/client';
import { PLATFORM_TEMPLATES } from '../apps/api/src/modules/templates/platform-templates';
import { seedMethodology } from './methodology-seed';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  // Upsert 8 platform templates.
  for (const seed of PLATFORM_TEMPLATES) {
    const existing = await prisma.template.findFirst({
      where: { kind: TemplateKind.platform, title: seed.title },
    });

    if (existing) {
      await prisma.templateStep.deleteMany({ where: { templateId: existing.id } });
      await prisma.template.update({
        where: { id: existing.id },
        data: {
          description: seed.description,
          steps: {
            create: seed.steps.map((s) => ({ title: s.title, orderIndex: s.orderIndex })),
          },
        },
      });
    } else {
      await prisma.template.create({
        data: {
          kind: TemplateKind.platform,
          title: seed.title,
          description: seed.description,
          steps: {
            create: seed.steps.map((s) => ({ title: s.title, orderIndex: s.orderIndex })),
          },
        },
      });
    }
  }

  const count = await prisma.template.count({ where: { kind: 'platform' } });
  // eslint-disable-next-line no-console
  console.log(`Seeded platform templates: ${count}`);

  const methodologyArticles = await seedMethodology(prisma);
  // eslint-disable-next-line no-console
  console.log(`Seeded methodology articles: ${methodologyArticles}`);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    // eslint-disable-next-line no-console
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
