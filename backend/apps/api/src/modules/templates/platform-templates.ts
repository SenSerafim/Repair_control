export interface PlatformTemplateSeed {
  slug: string;
  title: string;
  description: string;
  steps: { title: string; orderIndex: number }[];
}

/**
 * 8 платформенных шаблонов этапов из ТЗ §12.
 * Названия шагов — базовый скелет; заказчик/бригадир дополняют подшагами в проекте.
 */
export const PLATFORM_TEMPLATES: PlatformTemplateSeed[] = [
  {
    slug: 'demolition',
    title: 'Демонтаж',
    description: 'Снятие покрытий, вынос мусора, подготовка помещения.',
    steps: [
      { title: 'Защита окон, дверей, сантехники', orderIndex: 0 },
      { title: 'Демонтаж напольных покрытий', orderIndex: 1 },
      { title: 'Демонтаж обоев/штукатурки', orderIndex: 2 },
      { title: 'Демонтаж плитки', orderIndex: 3 },
      { title: 'Вывоз строительного мусора', orderIndex: 4 },
      { title: 'Финальная уборка после демонтажа', orderIndex: 5 },
    ],
  },
  {
    slug: 'electrical',
    title: 'Электрика',
    description: 'Разводка электрики, установка розеток, освещения.',
    steps: [
      { title: 'Согласование схемы электрики с заказчиком', orderIndex: 0 },
      { title: 'Штробление стен под кабель', orderIndex: 1 },
      { title: 'Прокладка кабеля по проекту', orderIndex: 2 },
      { title: 'Монтаж подрозетников', orderIndex: 3 },
      { title: 'Установка автоматов и щитка', orderIndex: 4 },
      { title: 'Прозвон и проверка сопротивления изоляции', orderIndex: 5 },
      { title: 'Установка розеток и выключателей', orderIndex: 6 },
      { title: 'Монтаж светильников', orderIndex: 7 },
    ],
  },
  {
    slug: 'plumbing',
    title: 'Сантехника',
    description: 'Разводка труб, монтаж сантехнического оборудования.',
    steps: [
      { title: 'Согласование схемы сантехники', orderIndex: 0 },
      { title: 'Демонтаж старого оборудования', orderIndex: 1 },
      { title: 'Разводка водопровода (ХВС/ГВС)', orderIndex: 2 },
      { title: 'Разводка канализации', orderIndex: 3 },
      { title: 'Опрессовка системы (24 часа)', orderIndex: 4 },
      { title: 'Установка унитаза', orderIndex: 5 },
      { title: 'Установка ванны/душа', orderIndex: 6 },
      { title: 'Установка смесителей и раковины', orderIndex: 7 },
    ],
  },
  {
    slug: 'plastering',
    title: 'Штукатурка и стяжка',
    description: 'Выравнивание стен и полов.',
    steps: [
      { title: 'Установка маяков на стены', orderIndex: 0 },
      { title: 'Штукатурка стен по маякам', orderIndex: 1 },
      { title: 'Снятие маяков, заделка отверстий', orderIndex: 2 },
      { title: 'Гидроизоляция санузла', orderIndex: 3 },
      { title: 'Установка маяков на полу', orderIndex: 4 },
      { title: 'Заливка стяжки', orderIndex: 5 },
      { title: 'Набор прочности стяжки (28 дней)', orderIndex: 6 },
    ],
  },
  {
    slug: 'tiling',
    title: 'Плиточные работы',
    description: 'Укладка керамической плитки/керамогранита.',
    steps: [
      { title: 'Раскладка плитки, разметка', orderIndex: 0 },
      { title: 'Грунтовка основания', orderIndex: 1 },
      { title: 'Укладка плитки на пол', orderIndex: 2 },
      { title: 'Укладка плитки на стены', orderIndex: 3 },
      { title: 'Затирка швов', orderIndex: 4 },
      { title: 'Герметизация стыков', orderIndex: 5 },
    ],
  },
  {
    slug: 'painting',
    title: 'Покраска и обои',
    description: 'Финишная отделка стен и потолков.',
    steps: [
      { title: 'Шпатлёвка стен (стартовая)', orderIndex: 0 },
      { title: 'Шпатлёвка стен (финишная)', orderIndex: 1 },
      { title: 'Шлифовка и грунтовка', orderIndex: 2 },
      { title: 'Покраска потолка', orderIndex: 3 },
      { title: 'Поклейка обоев / покраска стен', orderIndex: 4 },
      { title: 'Установка плинтусов и галтелей', orderIndex: 5 },
    ],
  },
  {
    slug: 'floor-pouring',
    title: 'Заливка полов',
    description: 'Наливной пол, финишные полы.',
    steps: [
      { title: 'Подготовка основания, грунтовка', orderIndex: 0 },
      { title: 'Установка демпферной ленты по периметру', orderIndex: 1 },
      { title: 'Заливка самонивелирующегося пола', orderIndex: 2 },
      { title: 'Набор прочности (7 дней)', orderIndex: 3 },
      { title: 'Укладка финишного покрытия', orderIndex: 4 },
    ],
  },
  {
    slug: 'air-conditioning',
    title: 'Кондиционирование',
    description: 'Установка и подключение систем кондиционирования.',
    steps: [
      { title: 'Согласование места установки', orderIndex: 0 },
      { title: 'Прокладка трасс в стенах', orderIndex: 1 },
      { title: 'Установка наружного блока', orderIndex: 2 },
      { title: 'Установка внутреннего блока', orderIndex: 3 },
      { title: 'Заправка фреона', orderIndex: 4 },
      { title: 'Пусконаладка, тестовый прогон', orderIndex: 5 },
    ],
  },
];
