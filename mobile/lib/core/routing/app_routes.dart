/// Централизованный список маршрутов. Path-шаблоны синхронизированы
/// с deep-link-payload'ами из FCM (ТЗ v3 §15.2).
///
/// Шаблоны (со `:param`) используются в `GoRouter.routes`. Helper-методы
/// `*With(...)` — для построения путей при `context.push(...)` чтобы
/// избежать ad-hoc string interpolation в экранах.
class AppRoutes {
  const AppRoutes._();

  // Splash / Auth.
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const recovery = '/recovery';

  // Home shell.
  static const home = '/home';
  static const projects = '/projects';
  static const projectsCreate = '/projects/create';
  static const projectsArchive = '/projects/archive';
  static const projectsSearch = '/projects/search';
  static const projectsJoinByCode = '/projects/join-by-code';
  static String projectsJoinByCodeWith(String code) =>
      '/projects/join-by-code?code=$code';
  static const projectDetail = '/projects/:projectId';
  static const projectEdit = '/projects/:projectId/edit';

  static String projectDetailWith(String projectId) => '/projects/$projectId';
  static String projectEditWith(String projectId) =>
      '/projects/$projectId/edit';

  // Tabs (root-level в HomeShell).
  static const contractors = '/contractors';
  static const chats = '/chats';
  static const chatDetail = '/chats/:chatId';
  static String chatDetailWith(String chatId) => '/chats/$chatId';

  // Cluster A — A2 (добавление участников). Маршруты живут под /projects/:projectId/team/.
  static const projectTeam = '/projects/:projectId/team';
  static String projectTeamWith(String projectId) =>
      '/projects/$projectId/team';
  static const projectAddMember = '/projects/:projectId/team/add';
  static String projectAddMemberWith(String projectId) =>
      '/projects/$projectId/team/add';
  static const projectMemberFound = '/projects/:projectId/team/found';
  static String projectMemberFoundWith(String projectId) =>
      '/projects/$projectId/team/found';
  static const projectMemberNotFound = '/projects/:projectId/team/not-found';
  static String projectMemberNotFoundWith(String projectId) =>
      '/projects/$projectId/team/not-found';
  static const projectAssignStage = '/projects/:projectId/team/stage';
  static String projectAssignStageWith(String projectId) =>
      '/projects/$projectId/team/stage';
  static const projectAddRepresentative =
      '/projects/:projectId/team/representative/add';
  static String projectAddRepresentativeWith(String projectId) =>
      '/projects/$projectId/team/representative/add';
  static const projectRepRights = '/projects/:projectId/team/representative/rights';
  static String projectRepRightsWith(String projectId) =>
      '/projects/$projectId/team/representative/rights';

  // Profile.
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileRoleSwitcher = '/profile/switch-role';
  static const profileRoles = '/profile/roles';
  static const profileRolesSwitched = '/profile/roles/switched';
  static const profileRepRights = '/profile/rep-rights';
  static const profileLanguage = '/profile/language';
  static const profileHelp = '/profile/help';
  static const profileFaqDetail = '/profile/help/:itemId';
  static String profileFaqDetailWith(String itemId) => '/profile/help/$itemId';
  static const profileFeedback = '/profile/feedback';
  static const profileNotifSettings = '/profile/notifications';

  // Tools (in Profile).
  static const profileTools = '/profile/tools';
  static const profileToolAdd = '/profile/tools/add';
  static const profileToolDetail = '/profile/tools/:toolId';
  static String profileToolDetailWith(String toolId) =>
      '/profile/tools/$toolId';

  // Approvals (root + per-project).
  static const approvals = '/approvals';
  static const approvalDetail = '/approvals/:approvalId';
  static String approvalDetailWith(String approvalId) =>
      '/approvals/$approvalId';

  /// Согласование плана работ — вложен в проект (доступен из ConsoleScreen,
  /// баннеров и push-уведомлений).
  static const projectPlanApproval = '/projects/:projectId/plan-approval';
  static String projectPlanApprovalWith(String projectId) =>
      '/projects/$projectId/plan-approval';

  /// Полноэкранный результат согласования (`d-approved` / `d-rejected`).
  /// Открывается через `context.replace` после approve/reject в sheet.
  static const approvalResult =
      '/projects/:projectId/approvals/:approvalId/result';
  static String approvalResultWith(
    String projectId,
    String approvalId,
    String status,
  ) =>
      '/projects/$projectId/approvals/$approvalId/result?status=$status';

  /// Список экспортов проекта (открывается из FeedScreen, DocumentsScreen,
  /// push-уведомлений `kind=export_*`).
  static const projectExports = '/projects/:projectId/exports';
  static String projectExportsWith(String projectId) =>
      '/projects/$projectId/exports';

  // Stages / steps (вложены в /projects/:projectId).
  static const stageDetail = '/projects/:projectId/stages/:stageId';
  static const stepDetail =
      '/projects/:projectId/stages/:stageId/steps/:stepId';
  static String stageDetailWith({
    required String projectId,
    required String stageId,
  }) =>
      '/projects/$projectId/stages/$stageId';
  static String stepDetailWith({
    required String projectId,
    required String stageId,
    required String stepId,
  }) =>
      '/projects/$projectId/stages/$stageId/steps/$stepId';

  /// Полноэкранный ответ на вопрос — `d-question-reply`. Открывается из
  /// карточки вопроса в StepDetailScreen.
  static const questionReply =
      '/projects/:projectId/stages/:stageId/steps/:stepId/questions/:questionId/reply';
  static String questionReplyWith({
    required String projectId,
    required String stageId,
    required String stepId,
    required String questionId,
  }) =>
      '/projects/$projectId/stages/$stageId/steps/$stepId/questions/$questionId/reply';

  // Templates flow (Кластер C).
  static const stagesTemplates = '/projects/:projectId/stages/templates';
  static String stagesTemplatesWith(String projectId) =>
      '/projects/$projectId/stages/templates';
  static const stagesTemplatePreview =
      '/projects/:projectId/stages/templates/:templateId/preview';
  static String stagesTemplatePreviewWith({
    required String projectId,
    required String templateId,
  }) =>
      '/projects/$projectId/stages/templates/$templateId/preview';
  static const stageCreated = '/projects/:projectId/stages/created';
  static String stageCreatedWith({
    required String projectId,
    required String stageId,
  }) =>
      '/projects/$projectId/stages/created?stageId=$stageId';

  // Cluster E — финансы/материалы/самозакупы/инструмент.
  static const materialEditPos =
      '/projects/:projectId/materials/:requestId/items/:itemId/edit';
  static String materialEditPosWith({
    required String projectId,
    required String requestId,
    required String itemId,
  }) =>
      '/projects/$projectId/materials/$requestId/items/$itemId/edit';

  static const selfpurchaseCreate =
      '/projects/:projectId/selfpurchases/new';
  static String selfpurchaseCreateWith(String projectId) =>
      '/projects/$projectId/selfpurchases/new';

  static const selfpurchaseDetail =
      '/projects/:projectId/selfpurchases/:id';
  static String selfpurchaseDetailWith({
    required String projectId,
    required String id,
  }) =>
      '/projects/$projectId/selfpurchases/$id';

  static const selfpurchaseReject =
      '/projects/:projectId/selfpurchases/:id/reject';
  static String selfpurchaseRejectWith({
    required String projectId,
    required String id,
  }) =>
      '/projects/$projectId/selfpurchases/$id/reject';

  static const toolIssue = '/projects/:projectId/tools/new';
  static String toolIssueWith(String projectId) =>
      '/projects/$projectId/tools/new';

  // Payments / Documents / Notifications / Methodology — root-level
  // экраны, вызываемые из FCM-deep-link и из projectDetail-меню.
  static const paymentDetail = '/payments/:paymentId';
  static String paymentDetailWith(String paymentId) =>
      '/payments/$paymentId';

  static const documentDetail = '/documents/:documentId';
  static const documentView = '/documents/:documentId/view';
  static String documentDetailWith(String documentId) =>
      '/documents/$documentId';
  static String documentViewWith(String documentId) =>
      '/documents/$documentId/view';

  static const notifications = '/notifications';

  static const supportContacts = '/support';

  static const methodology = '/methodology';
  static const methodologySearch = '/methodology/search';
  static const methodologySection = '/methodology/sections/:sectionId';
  static const methodologyArticle = '/methodology/articles/:articleId';
  static String methodologySectionWith(String sectionId) =>
      '/methodology/sections/$sectionId';
  static String methodologyArticleWith(String articleId) =>
      '/methodology/articles/$articleId';

  static const knowledge = '/knowledge';
  static const knowledgeSearch = '/knowledge/search';
  static const knowledgeCategory = '/knowledge/categories/:categoryId';
  static const knowledgeArticle = '/knowledge/articles/:articleId';
  static String knowledgeCategoryWith(String categoryId) =>
      '/knowledge/categories/$categoryId';
  static String knowledgeArticleWith(String articleId) =>
      '/knowledge/articles/$articleId';
  static String knowledgeWithModule(String moduleSlug) =>
      '/knowledge?moduleSlug=$moduleSlug';
}
