import * as crypto from 'crypto';
import { PrismaClient } from '@prisma/client';

/**
 * Демонстрационный seed методички (ТЗ §8 спринт 3 день 6): 2 раздела × 3 статьи.
 * Используется e2e-инспектором (search по «шпатлёвка») и как база для QA.
 * Идемпотентный upsert по title раздела/статьи.
 */

interface ArticleSeed {
  title: string;
  body: string;
}

interface SectionSeed {
  title: string;
  orderIndex: number;
  articles: ArticleSeed[];
}

const SECTIONS: SectionSeed[] = [
  {
    title: 'Электрика',
    orderIndex: 0,
    articles: [
      {
        title: 'Монтаж розеток и выключателей',
        body:
          'Перед монтажом убедитесь, что питание отключено. Используйте индикаторную отвёртку.\n' +
          'Подключайте фазу к фазному выводу, ноль — к нулевому. Заземление — к земляной шине.\n' +
          'После установки проверяйте тестером отсутствие короткого замыкания.',
      },
      {
        title: 'Прокладка силового кабеля',
        body:
          'Сечение кабеля выбирается по расчётной мощности потребителей. На кухню — 2.5 мм², на розетки 1.5 мм².\n' +
          'Используйте штробление по бетону шириной 2 см. Прокладка строго горизонтальная или вертикальная.',
      },
      {
        title: 'Проверка УЗО и автоматов',
        body:
          'После монтажа щита запустите тестовую нагрузку. Проверьте срабатывание УЗО кнопкой TEST.\n' +
          'Автоматы маркируйте по зонам (кухня, спальня, ванная).',
      },
    ],
  },
  {
    title: 'Плиточные работы',
    orderIndex: 1,
    articles: [
      {
        title: 'Подготовка основания',
        body:
          'Поверхность должна быть ровной, сухой и очищенной от пыли. Перепады > 3 мм выравниваются стяжкой.\n' +
          'Грунтовка — обязательный этап перед укладкой. Используйте адгезионные праймеры на бетон.',
      },
      {
        title: 'Шпатлевание швов',
        body:
          'После укладки плитки проводится шпатлёвка швов затирочной смесью. Время высыхания 24 ч.\n' +
          'Формат шва подбирается под дизайн — от 1.5 мм (бесшовная) до 5 мм (пользовательский).',
      },
      {
        title: 'Укладка крупноформатной плитки',
        body:
          'Плитка 60×60 и более требует повышенной ровности основания. Используйте гребёнку 10 мм.\n' +
          'Наносите клей на обе поверхности — основание и плитку — для исключения пустот.',
      },
    ],
  },
];

const computeEtag = (title: string, body: string): string =>
  crypto.createHash('sha256').update(`${title}\n${body}\n`).digest('hex');

export async function seedMethodology(prisma: PrismaClient): Promise<number> {
  let articlesCount = 0;
  for (const sec of SECTIONS) {
    const section = await prisma.methodologySection.upsert({
      where: { id: `seed-section-${sec.orderIndex}` },
      create: {
        id: `seed-section-${sec.orderIndex}`,
        title: sec.title,
        orderIndex: sec.orderIndex,
      },
      update: { title: sec.title, orderIndex: sec.orderIndex },
    });
    for (let i = 0; i < sec.articles.length; i++) {
      const a = sec.articles[i];
      const etag = computeEtag(a.title, a.body);
      await prisma.methodologyArticle.upsert({
        where: { id: `seed-article-${sec.orderIndex}-${i}` },
        create: {
          id: `seed-article-${sec.orderIndex}-${i}`,
          sectionId: section.id,
          title: a.title,
          body: a.body,
          orderIndex: i,
          version: 1,
          etag,
        },
        update: { title: a.title, body: a.body, orderIndex: i, etag },
      });
      articlesCount += 1;
    }
  }
  return articlesCount;
}
