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

  // Profile.
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileRoles = '/profile/roles';
  static const profileRepRights = '/profile/rep-rights';
  static const profileLanguage = '/profile/language';
  static const profileHelp = '/profile/help';
  static const profileFaqDetail = '/profile/help/:itemId';
  static String profileFaqDetailWith(String itemId) => '/profile/help/$itemId';
  static const profileFeedback = '/profile/feedback';
  static const profileNotifSettings = '/profile/notifications';

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

  static const methodology = '/methodology';
  static const methodologySearch = '/methodology/search';
  static const methodologySection = '/methodology/sections/:sectionId';
  static const methodologyArticle = '/methodology/articles/:articleId';
  static String methodologySectionWith(String sectionId) =>
      '/methodology/sections/$sectionId';
  static String methodologyArticleWith(String articleId) =>
      '/methodology/articles/$articleId';
}
