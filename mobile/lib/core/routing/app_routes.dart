/// Централизованный список маршрутов. Path-шаблоны синхронизированы
/// с deep-link-payload'ами из FCM (ТЗ v3 §15.2).
class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const recovery = '/recovery';

  static const home = '/home';
  static const projects = '/projects';
  static const projectsCreate = '/projects/create';
  static const projectsArchive = '/projects/archive';
  static const projectsSearch = '/projects/search';
  static const projectDetail = '/projects/:projectId';
  static const projectEdit = '/projects/:projectId/edit';

  static const contractors = '/contractors';
  static const chats = '/chats';
  static const chatDetail = '/chats/:chatId';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileRoles = '/profile/roles';
  static const profileRepRights = '/profile/rep-rights';
  static const profileLanguage = '/profile/language';
  static const profileHelp = '/profile/help';
  static const profileFaqDetail = '/profile/help/:itemId';
  static const profileFeedback = '/profile/feedback';
  static const profileNotifSettings = '/profile/notifications';

  static const approvals = '/approvals';
  static const approvalDetail = '/approvals/:approvalId';

  static const stageDetail = '/projects/:projectId/stages/:stageId';
  static const stepDetail =
      '/projects/:projectId/stages/:stageId/steps/:stepId';
}
