//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:repair_control_api/src/auth/api_key_auth.dart';
import 'package:repair_control_api/src/auth/basic_auth.dart';
import 'package:repair_control_api/src/auth/bearer_auth.dart';
import 'package:repair_control_api/src/auth/oauth.dart';
import 'package:repair_control_api/src/api/admin_api.dart';
import 'package:repair_control_api/src/api/admin_audit_api.dart';
import 'package:repair_control_api/src/api/admin_broadcasts_api.dart';
import 'package:repair_control_api/src/api/admin_projects_api.dart';
import 'package:repair_control_api/src/api/admin_users_api.dart';
import 'package:repair_control_api/src/api/approvals_api.dart';
import 'package:repair_control_api/src/api/auth_api.dart';
import 'package:repair_control_api/src/api/chats_api.dart';
import 'package:repair_control_api/src/api/documents_api.dart';
import 'package:repair_control_api/src/api/feed_exports_api.dart';
import 'package:repair_control_api/src/api/feedback_api.dart';
import 'package:repair_control_api/src/api/files_api.dart';
import 'package:repair_control_api/src/api/health_api.dart';
import 'package:repair_control_api/src/api/legal_api.dart';
import 'package:repair_control_api/src/api/legal_public_api.dart';
import 'package:repair_control_api/src/api/materials_api.dart';
import 'package:repair_control_api/src/api/me_api.dart';
import 'package:repair_control_api/src/api/methodology_api.dart';
import 'package:repair_control_api/src/api/notes_api.dart';
import 'package:repair_control_api/src/api/notifications_api.dart';
import 'package:repair_control_api/src/api/payments_api.dart';
import 'package:repair_control_api/src/api/projects_api.dart';
import 'package:repair_control_api/src/api/questions_api.dart';
import 'package:repair_control_api/src/api/selfpurchases_api.dart';
import 'package:repair_control_api/src/api/stages_api.dart';
import 'package:repair_control_api/src/api/steps_api.dart';
import 'package:repair_control_api/src/api/templates_api.dart';
import 'package:repair_control_api/src/api/tools_api.dart';

class RepairControlApi {
  static const String basePath = r'http://localhost';

  final Dio dio;
  RepairControlApi({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : 
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Get AdminApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminApi getAdminApi() {
    return AdminApi(dio);
  }

  /// Get AdminAuditApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminAuditApi getAdminAuditApi() {
    return AdminAuditApi(dio);
  }

  /// Get AdminBroadcastsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminBroadcastsApi getAdminBroadcastsApi() {
    return AdminBroadcastsApi(dio);
  }

  /// Get AdminProjectsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminProjectsApi getAdminProjectsApi() {
    return AdminProjectsApi(dio);
  }

  /// Get AdminUsersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminUsersApi getAdminUsersApi() {
    return AdminUsersApi(dio);
  }

  /// Get ApprovalsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ApprovalsApi getApprovalsApi() {
    return ApprovalsApi(dio);
  }

  /// Get AuthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthApi getAuthApi() {
    return AuthApi(dio);
  }

  /// Get ChatsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ChatsApi getChatsApi() {
    return ChatsApi(dio);
  }

  /// Get DocumentsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DocumentsApi getDocumentsApi() {
    return DocumentsApi(dio);
  }

  /// Get FeedExportsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  FeedExportsApi getFeedExportsApi() {
    return FeedExportsApi(dio);
  }

  /// Get FeedbackApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  FeedbackApi getFeedbackApi() {
    return FeedbackApi(dio);
  }

  /// Get FilesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  FilesApi getFilesApi() {
    return FilesApi(dio);
  }

  /// Get HealthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  HealthApi getHealthApi() {
    return HealthApi(dio);
  }

  /// Get LegalApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  LegalApi getLegalApi() {
    return LegalApi(dio);
  }

  /// Get LegalPublicApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  LegalPublicApi getLegalPublicApi() {
    return LegalPublicApi(dio);
  }

  /// Get MaterialsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MaterialsApi getMaterialsApi() {
    return MaterialsApi(dio);
  }

  /// Get MeApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MeApi getMeApi() {
    return MeApi(dio);
  }

  /// Get MethodologyApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MethodologyApi getMethodologyApi() {
    return MethodologyApi(dio);
  }

  /// Get NotesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  NotesApi getNotesApi() {
    return NotesApi(dio);
  }

  /// Get NotificationsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  NotificationsApi getNotificationsApi() {
    return NotificationsApi(dio);
  }

  /// Get PaymentsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PaymentsApi getPaymentsApi() {
    return PaymentsApi(dio);
  }

  /// Get ProjectsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ProjectsApi getProjectsApi() {
    return ProjectsApi(dio);
  }

  /// Get QuestionsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  QuestionsApi getQuestionsApi() {
    return QuestionsApi(dio);
  }

  /// Get SelfpurchasesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SelfpurchasesApi getSelfpurchasesApi() {
    return SelfpurchasesApi(dio);
  }

  /// Get StagesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  StagesApi getStagesApi() {
    return StagesApi(dio);
  }

  /// Get StepsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  StepsApi getStepsApi() {
    return StepsApi(dio);
  }

  /// Get TemplatesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TemplatesApi getTemplatesApi() {
    return TemplatesApi(dio);
  }

  /// Get ToolsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ToolsApi getToolsApi() {
    return ToolsApi(dio);
  }
}
