import '../../../core/access/domain_actions.dart';
import '../../../core/access/representative_rights.dart';

/// Человекочитаемая метка для DomainAction (P1.1).
/// Используется в `rep_rights_sheet` (Команда) и `rep_rights_screen` (Профиль)
/// для отображения списка делегированных прав представителя.
class RightLabel {
  const RightLabel({required this.title, required this.description});
  final String title;
  final String description;
}

/// Карта `RepresentativeRight` → русское название и пояснение.
///
/// Источник истины для 10 флагов `RepresentativeRights` (см.
/// `backend/libs/rbac/src/rbac.types.ts`). Тексты согласованы с
/// дизайном `design/Кластер B` и матрицей прав ТЗ §1.5.
///
/// `kRightsRu` (по `DomainAction`) исторически использовался как «список
/// всех возможных действий» в info-экране профиля; для UI выдачи прав
/// представителю используется именно эта карта.
const Map<RepresentativeRight, RightLabel> kRepresentativeRightLabels = {
  RepresentativeRight.canEditStages: RightLabel(
    title: 'Редактировать этапы и шаги',
    description:
        'Менять состав этапов, шаги, фото, документы. Без права создания '
        'этапов с нуля — для этого есть отдельное право ниже.',
  ),
  RepresentativeRight.canCreateStages: RightLabel(
    title: 'Создавать этапы без согласования',
    description:
        'Новый этап появляется сразу, как у заказчика. Без этого права '
        'создание этапа недоступно представителю.',
  ),
  RepresentativeRight.canApprove: RightLabel(
    title: 'Принимать решения по согласованиям',
    description:
        'Одобрять и отклонять планы, шаги, приёмки, диспуты — от имени '
        'заказчика.',
  ),
  RepresentativeRight.canSeeBudget: RightLabel(
    title: 'Видеть бюджет проекта',
    description: 'Полный бюджет, сметы по этапам, экспорт ленты финансов.',
  ),
  RepresentativeRight.canCreatePayments: RightLabel(
    title: 'Создавать и подтверждать выплаты',
    description: 'Авансы бригадиру и оплаты, диспуты по платежам.',
  ),
  RepresentativeRight.canManageMaterials: RightLabel(
    title: 'Управлять материалами',
    description: 'Создавать заявки на материалы, отмечать получение, закрывать.',
  ),
  RepresentativeRight.canManageTools: RightLabel(
    title: 'Управлять инструментом',
    description: 'Реестр инструмента, выдача мастерам, приёмка возвратов.',
  ),
  RepresentativeRight.canInviteMembers: RightLabel(
    title: 'Приглашать участников',
    description: 'Добавлять в проект бригадира, мастера, представителя.',
  ),
  RepresentativeRight.canManageTeam: RightLabel(
    title: 'Удалять участников',
    description:
        'Снимать участника из команды через карточку «Команда». Без права '
        'кнопка «Убрать из команды» скрыта.',
  ),
  RepresentativeRight.canAddRepresentative: RightLabel(
    title: 'Добавлять других представителей',
    description:
        'Делегировать часть полномочий ещё одному представителю — например, '
        'на время отъезда.',
  ),
};

/// Группировка делегированных прав для UI экрана/шита настройки.
/// Порядок и тексты согласованы с design/Кластер B (раздел «Команда»).
class RepresentativeRightGroup {
  const RepresentativeRightGroup({required this.title, required this.rights});
  final String title;
  final List<RepresentativeRight> rights;
}

const List<RepresentativeRightGroup> kRepresentativeRightGroups = [
  RepresentativeRightGroup(
    title: 'Управление проектом',
    rights: [
      RepresentativeRight.canEditStages,
      RepresentativeRight.canCreateStages,
    ],
  ),
  RepresentativeRightGroup(
    title: 'Команда',
    rights: [
      RepresentativeRight.canInviteMembers,
      RepresentativeRight.canAddRepresentative,
      RepresentativeRight.canManageTeam,
    ],
  ),
  RepresentativeRightGroup(
    title: 'Согласования',
    rights: [RepresentativeRight.canApprove],
  ),
  RepresentativeRightGroup(
    title: 'Финансы',
    rights: [
      RepresentativeRight.canSeeBudget,
      RepresentativeRight.canCreatePayments,
    ],
  ),
  RepresentativeRightGroup(
    title: 'Материалы и инструмент',
    rights: [
      RepresentativeRight.canManageMaterials,
      RepresentativeRight.canManageTools,
    ],
  ),
];

/// Карта DomainAction → русское название и пояснение.
/// Источник: ТЗ §1.5, дизайн design/Кластер B/A.
const Map<DomainAction, RightLabel> kRightsRu = {
  DomainAction.projectCreate: RightLabel(
    title: 'Создавать проекты',
    description: 'Может создавать новые ремонтные проекты от имени заказчика.',
  ),
  DomainAction.projectEdit: RightLabel(
    title: 'Редактировать проект',
    description: 'Менять название, адрес, бюджет, сроки проекта.',
  ),
  DomainAction.projectArchive: RightLabel(
    title: 'Архивировать проект',
    description: 'Переводить завершённый проект в архив.',
  ),
  DomainAction.projectInviteMember: RightLabel(
    title: 'Приглашать участников',
    description: 'Добавлять в проект бригадира, мастеров, представителей.',
  ),
  DomainAction.stageManage: RightLabel(
    title: 'Управлять этапами',
    description: 'Создавать, редактировать и закрывать этапы.',
  ),
  DomainAction.stageStart: RightLabel(
    title: 'Запускать этапы',
    description: 'Нажимать «Старт» — этап переходит в работу.',
  ),
  DomainAction.stagePause: RightLabel(
    title: 'Ставить этапы на паузу',
    description: 'Приостанавливать работы с указанием причины.',
  ),
  DomainAction.stepManage: RightLabel(
    title: 'Управлять шагами',
    description: 'Создавать и редактировать шаги внутри этапа.',
  ),
  DomainAction.stepAddSubstep: RightLabel(
    title: 'Добавлять подшаги',
    description: 'Дробить шаги на чек-лист подшагов.',
  ),
  DomainAction.stepPhotoUpload: RightLabel(
    title: 'Загружать фото к шагам',
    description: 'Прикреплять фотографии хода работ.',
  ),
  DomainAction.approvalList: RightLabel(
    title: 'Видеть все согласования',
    description: 'Открыт раздел «Согласования» с историей решений.',
  ),
  DomainAction.approvalRequest: RightLabel(
    title: 'Запрашивать согласование',
    description: 'Отправлять заказчику план, шаг или приёмку на одобрение.',
  ),
  DomainAction.approvalDecide: RightLabel(
    title: 'Принимать решения по согласованиям',
    description:
        'Одобрять или отклонять планы, шаги, приёмки от имени заказчика.',
  ),
  DomainAction.financeBudgetView: RightLabel(
    title: 'Видеть бюджет',
    description: 'Открыт раздел «Финансы» и сметы по этапам.',
  ),
  DomainAction.financeBudgetEdit: RightLabel(
    title: 'Менять бюджет',
    description: 'Корректировать суммы и распределение средств.',
  ),
  DomainAction.financePaymentCreateAdvance: RightLabel(
    title: 'Отправлять авансы',
    description: 'Создавать общий аванс из бюджета — бригадиру или напрямую мастеру.',
  ),
  DomainAction.financePaymentDistribute: RightLabel(
    title: 'Распределять авансы',
    description: 'Бригадир распределяет свой полученный аванс между мастерами. Представителю не делегируется.',
  ),
  DomainAction.materialsManage: RightLabel(
    title: 'Управлять материалами',
    description: 'Заказывать, отмечать получение, оспаривать поставки.',
  ),
  DomainAction.materialFinalize: RightLabel(
    title: 'Финализировать материалы',
    description: 'Закрывать список материалов после доставки.',
  ),
  DomainAction.selfPurchaseCreate: RightLabel(
    title: 'Создавать самозакуп',
    description:
        'Заявлять о самостоятельной покупке материалов с компенсацией.',
  ),
  DomainAction.selfPurchaseConfirm: RightLabel(
    title: 'Подтверждать самозакуп',
    description: 'Одобрять заявки на самозакуп от мастеров.',
  ),
  DomainAction.toolsAddToProject: RightLabel(
    title: 'Добавлять инструменты в проект',
    description: 'Создавать новый инструмент в проекте или привязывать из «Моих».',
  ),
  DomainAction.toolsClaim: RightLabel(
    title: 'Забирать инструмент',
    description: 'Отмечать «инструмент у меня». Никто не назначает за другого.',
  ),
  DomainAction.chatRead: RightLabel(
    title: 'Читать чаты',
    description: 'Доступ к разделу «Коммуникации».',
  ),
  DomainAction.chatWrite: RightLabel(
    title: 'Писать в чаты',
    description: 'Отправлять сообщения в проектных и этапных чатах.',
  ),
  DomainAction.chatCreatePersonal: RightLabel(
    title: 'Создавать личные чаты',
    description: 'Открывать диалоги один на один с участниками.',
  ),
  DomainAction.chatCreateGroup: RightLabel(
    title: 'Создавать групповые чаты',
    description: 'Создавать собственные группы внутри проекта.',
  ),
  DomainAction.chatToggleCustomerVisibility: RightLabel(
    title: 'Открывать чаты заказчику',
    description: 'Делать приватный чат бригады видимым для заказчика.',
  ),
  DomainAction.chatModerate: RightLabel(
    title: 'Модерировать чаты',
    description: 'Удалять чужие сообщения, исключать участников.',
  ),
  DomainAction.documentRead: RightLabel(
    title: 'Просматривать документы',
    description: 'Открыт раздел «Документы».',
  ),
  DomainAction.documentWrite: RightLabel(
    title: 'Загружать документы',
    description: 'Прикреплять договоры, акты, сметы.',
  ),
  DomainAction.documentDelete: RightLabel(
    title: 'Удалять документы',
    description: 'Стирать ранее загруженные файлы.',
  ),
  DomainAction.feedExport: RightLabel(
    title: 'Экспортировать историю',
    description: 'Скачивать ленту проекта в PDF или ZIP.',
  ),
  DomainAction.noteManage: RightLabel(
    title: 'Управлять заметками',
    description: 'Создавать и редактировать заметки к шагам.',
  ),
  DomainAction.questionManage: RightLabel(
    title: 'Управлять вопросами',
    description: 'Задавать и отвечать на вопросы по шагам.',
  ),
  DomainAction.methodologyRead: RightLabel(
    title: 'Читать методичку',
    description: 'Открыт раздел «Методичка» с инструкциями.',
  ),
  DomainAction.methodologyEdit: RightLabel(
    title: 'Редактировать методичку',
    description: 'Изменять статьи и разделы методички (admin-only).',
  ),
};

/// Группировка прав по логическим разделам — для UI rep_rights_sheet.
/// Не покрывает 100% actions: admin.* и `methodology.edit` намеренно скрыты.
const Map<String, List<DomainAction>> kRightsGrouped = {
  'Проект': [
    DomainAction.projectEdit,
    DomainAction.projectArchive,
    DomainAction.projectInviteMember,
  ],
  'Этапы и работы': [
    DomainAction.stageManage,
    DomainAction.stageStart,
    DomainAction.stagePause,
    DomainAction.stepManage,
  ],
  'Согласования': [DomainAction.approvalRequest, DomainAction.approvalDecide],
  'Финансы': [
    DomainAction.financeBudgetView,
    DomainAction.financePaymentCreateAdvance,
  ],
  'Материалы и инструменты': [
    DomainAction.materialsManage,
    DomainAction.toolsAddToProject,
    DomainAction.toolsClaim,
  ],
};
