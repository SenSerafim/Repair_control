import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/approvals/presentation/approval_detail_screen.dart';
import '../../features/approvals/presentation/approval_result_screen.dart';
import '../../features/approvals/presentation/approvals_screen.dart';
import '../../features/approvals/presentation/plan_approval_screen.dart';
import '../access/system_role.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/legal_acceptance_modal.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/recovery_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/chat/presentation/chat_conversation_screen.dart';
import '../../features/chat/presentation/chats_screen.dart';
import '../../features/documents/presentation/document_detail_screen.dart';
import '../../features/documents/presentation/document_upload_screen.dart';
import '../../features/documents/presentation/document_viewer_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/exports/presentation/exports_list_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/finance/presentation/advance_distribution_screen.dart';
import '../../features/finance/presentation/budget_screen.dart';
import '../../features/finance/presentation/create_advance_screen.dart';
import '../../features/finance/presentation/payment_detail_screen.dart';
import '../../features/finance/presentation/payments_list_screen.dart';
import '../../features/materials/presentation/create_material_screen.dart';
import '../../features/materials/presentation/edit_purchased_item_screen.dart';
import '../../features/materials/presentation/material_detail_screen.dart';
import '../../features/materials/presentation/materials_list_screen.dart';
import '../../features/methodology/presentation/article_screen.dart';
import '../../features/methodology/presentation/methodology_screen.dart';
import '../../features/methodology/presentation/methodology_search_screen.dart';
import '../../features/methodology/presentation/methodology_section_screen.dart';
import '../../features/knowledge_base/presentation/knowledge_article_screen.dart';
import '../../features/knowledge_base/presentation/knowledge_category_screen.dart';
import '../../features/knowledge_base/presentation/knowledge_screen.dart';
import '../../features/knowledge_base/presentation/knowledge_search_screen.dart';
import '../../features/support_contacts/presentation/support_contacts_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/notifications/application/notifications_controller.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/faq_detail_screen.dart';
import '../../features/profile/presentation/feedback_screen.dart';
import '../../features/profile/presentation/help_screen.dart';
import '../../features/profile/presentation/language_screen.dart';
import '../../features/profile/presentation/notification_settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/rep_rights_screen.dart';
import '../../features/profile/presentation/role_switched_screen.dart';
import '../../features/profile/presentation/role_switcher_screen.dart';
import '../../features/profile/presentation/roles_screen.dart';
import '../../features/projects/presentation/archive_screen.dart';
import '../../features/projects/presentation/console_screen.dart';
import '../../features/projects/presentation/create_project_screen.dart';
import '../../features/projects/presentation/edit_project_screen.dart';
import '../../features/projects/presentation/join_by_code_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/projects/presentation/search_screen.dart';
import '../../features/selfpurchase/presentation/create_selfpurchase_screen.dart';
import '../../features/selfpurchase/presentation/reject_selfpurchase_screen.dart';
import '../../features/selfpurchase/presentation/selfpurchase_detail_screen.dart';
import '../../features/selfpurchase/presentation/selfpurchases_screen.dart';
import '../../features/stages/presentation/create_stage_screen.dart';
import '../../features/stages/presentation/stage_created_screen.dart';
import '../../features/stages/presentation/stage_detail_screen.dart';
import '../../features/stages/presentation/stages_screen.dart';
import '../../features/stages/presentation/template_preview_screen.dart';
import '../../features/stages/presentation/templates_screen.dart';
import '../../features/steps/presentation/question_reply_screen.dart';
import '../../features/steps/presentation/step_detail_screen.dart';
import '../../features/projects/domain/membership.dart';
import '../../features/team/presentation/add_member_screen.dart';
import '../../features/team/presentation/add_representative_screen.dart';
import '../../features/team/presentation/assign_stage_screen.dart';
import '../../features/team/presentation/contractors_screen.dart';
import '../../features/team/presentation/member_found_screen.dart';
import '../../features/team/presentation/member_not_found_screen.dart';
import '../../features/team/presentation/project_rep_rights_screen.dart';
import '../../features/team/presentation/team_screen.dart';
import '../../features/tools/presentation/add_tool_screen.dart';
import '../../features/tools/presentation/issue_tool_screen.dart';
import '../../features/tools/presentation/my_tools_screen.dart';
import '../../features/tools/presentation/tool_detail_screen.dart';
import '../../features/tools/presentation/tool_issuances_screen.dart';
import '../../shared/widgets/widgets.dart';
import 'app_routes.dart';
import 'transitions.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthRefreshListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final isAuthArea = loc == AppRoutes.welcome ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.recovery;

      if (auth.status == AuthStatus.unknown) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return isAuthArea ? null : AppRoutes.welcome;
      }
      if (loc == AppRoutes.splash || isAuthArea) {
        return AppRoutes.projects;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.recovery,
        builder: (_, __) => const RecoveryScreen(),
      ),
      // P2.4: deep-link /invite/:code (root-level).
      // repair-control://invite/123456 (Android scheme + iOS URL Type)
      // или https-link с тем же path попадает сюда. Перенаправляем на
      // вложенный /projects/join-by-code?code=123456.
      GoRoute(
        path: '/invite/:code',
        redirect: (_, state) {
          final code = state.pathParameters['code'];
          if (code == null || code.isEmpty) return AppRoutes.projects;
          return AppRoutes.projectsJoinByCodeWith(code);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => _HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.projects,
            builder: (_, __) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                pageBuilder:
                    slideUpPage((_, __) => const CreateProjectScreen()),
              ),
              GoRoute(
                path: 'archive',
                pageBuilder: slideLeftPage((_, __) => const ArchiveScreen()),
              ),
              GoRoute(
                path: 'search',
                pageBuilder: fadePage((_, __) => const SearchScreen()),
              ),
              // P2: invite-by-code — путь объявлен ДО :projectId, чтобы
              // 'join-by-code' не попал в paramsMatcher как projectId.
              GoRoute(
                path: 'join-by-code',
                pageBuilder: slideUpPage(
                  (_, state) => JoinByCodeScreen(
                    prefilledCode: state.uri.queryParameters['code'],
                  ),
                ),
              ),
              GoRoute(
                path: ':projectId',
                pageBuilder: slideLeftPage(
                  (_, state) => ConsoleScreen(
                    projectId: state.pathParameters['projectId']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: slideLeftPage(
                      (_, state) => EditProjectScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'team',
                    pageBuilder: slideLeftPage(
                      (_, state) => TeamScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: slideLeftPage(
                          (_, state) => AddMemberScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'found',
                        pageBuilder: slideLeftPage(
                          (_, state) => MemberFoundScreen(
                            projectId: state.pathParameters['projectId']!,
                            args: state.extra! as MemberFoundArgs,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'not-found',
                        pageBuilder: slideLeftPage(
                          (_, state) => MemberNotFoundScreen(
                            projectId: state.pathParameters['projectId']!,
                            phone: (state.extra ?? '') as String,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'stage',
                        pageBuilder: slideLeftPage(
                          (_, state) => AssignStageScreen(
                            projectId: state.pathParameters['projectId']!,
                            args: state.extra! as MemberFoundArgs,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'representative/add',
                        pageBuilder: slideLeftPage(
                          (_, state) => AddRepresentativeScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'representative/rights',
                        pageBuilder: slideLeftPage(
                          (_, state) => ProjectRepRightsScreen(
                            projectId: state.pathParameters['projectId']!,
                            user: state.extra! as ProjectMemberUser,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'stages',
                    pageBuilder: slideLeftPage(
                      (_, state) => StagesScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'create',
                        pageBuilder: slideUpPage(
                          (_, state) => CreateStageScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'created',
                        pageBuilder: slideUpPage(
                          (_, state) => StageCreatedScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                            stageId: state.uri.queryParameters['stageId'],
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'templates',
                        pageBuilder: slideLeftPage(
                          (_, state) => TemplatesScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: ':templateId/preview',
                            pageBuilder: slideLeftPage(
                              (_, state) => TemplatePreviewScreen(
                                projectId:
                                    state.pathParameters['projectId']!,
                                templateId:
                                    state.pathParameters['templateId']!,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: ':stageId',
                        pageBuilder: slideLeftPage(
                          (_, state) => StageDetailScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                            stageId: state.pathParameters['stageId']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'steps/:stepId',
                            pageBuilder: slideLeftPage(
                              (_, state) => StepDetailScreen(
                                projectId:
                                    state.pathParameters['projectId']!,
                                stageId:
                                    state.pathParameters['stageId']!,
                                stepId:
                                    state.pathParameters['stepId']!,
                              ),
                            ),
                            routes: [
                              GoRoute(
                                path: 'questions/:questionId/reply',
                                pageBuilder: slideLeftPage(
                                  (_, state) => QuestionReplyScreen(
                                    projectId:
                                        state.pathParameters['projectId']!,
                                    stageId:
                                        state.pathParameters['stageId']!,
                                    stepId:
                                        state.pathParameters['stepId']!,
                                    questionId: state
                                        .pathParameters['questionId']!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'notes',
                    pageBuilder: slideLeftPage(
                      (_, state) => NotesScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'approvals',
                    pageBuilder: slideLeftPage(
                      (_, state) => ApprovalsScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: ':approvalId',
                        pageBuilder: slideLeftPage(
                          (_, state) => ApprovalDetailScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                            approvalId:
                                state.pathParameters['approvalId']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'result',
                            pageBuilder: slideLeftPage(
                              (_, state) => ApprovalResultScreen(
                                projectId:
                                    state.pathParameters['projectId']!,
                                approvalId:
                                    state.pathParameters['approvalId']!,
                                status: state.uri.queryParameters['status'] ??
                                    'approved',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'plan-approval',
                    pageBuilder: slideLeftPage(
                      (_, state) => PlanApprovalScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'budget',
                    pageBuilder: slideLeftPage(
                      (_, state) => BudgetScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'payments',
                    pageBuilder: slideLeftPage(
                      (_, state) => PaymentsListScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: slideUpPage(
                          (_, state) => CreateAdvanceScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'advance',
                        pageBuilder: slideUpPage(
                          (_, state) => CreateAdvanceScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':paymentId/distribute',
                        pageBuilder: slideLeftPage(
                          (_, state) => AdvanceDistributionScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                            paymentId: state.pathParameters['paymentId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'materials',
                    pageBuilder: slideLeftPage(
                      (_, state) => MaterialsListScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: slideUpPage(
                          (_, state) => CreateMaterialScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':requestId',
                        pageBuilder: slideLeftPage(
                          (_, state) => MaterialDetailScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                            requestId:
                                state.pathParameters['requestId']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'items/:itemId/edit',
                            pageBuilder: slideUpPage(
                              (_, state) => EditPurchasedItemScreen(
                                projectId:
                                    state.pathParameters['projectId']!,
                                requestId:
                                    state.pathParameters['requestId']!,
                                itemId:
                                    state.pathParameters['itemId']!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'selfpurchases',
                    pageBuilder: slideLeftPage(
                      (_, state) => SelfpurchasesScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: slideUpPage(
                          (_, state) => CreateSelfPurchaseScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        pageBuilder: slideLeftPage(
                          (_, state) => SelfPurchaseDetailScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                            id: state.pathParameters['id']!,
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: 'reject',
                            pageBuilder: slideUpPage(
                              (_, state) => RejectSelfPurchaseScreen(
                                projectId:
                                    state.pathParameters['projectId']!,
                                id: state.pathParameters['id']!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'tools',
                    pageBuilder: slideLeftPage(
                      (_, state) => ToolIssuancesScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: slideUpPage(
                          (_, state) => IssueToolScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'chats',
                    pageBuilder: slideLeftPage(
                      (_, state) => ProjectChatsScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'documents',
                    pageBuilder: slideLeftPage(
                      (_, state) => DocumentsScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'upload',
                        pageBuilder: slideUpPage(
                          (_, state) => DocumentUploadScreen(
                            projectId:
                                state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'feed',
                    pageBuilder: slideLeftPage(
                      (_, state) => FeedScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'exports',
                    pageBuilder: slideLeftPage(
                      (_, state) => ExportsListScreen(
                        projectId: state.pathParameters['projectId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.contractors,
            builder: (_, __) => const ContractorsScreen(),
          ),
          GoRoute(
            path: AppRoutes.chats,
            builder: (_, __) => const ChatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'tools',
                pageBuilder:
                    slideLeftPage((_, __) => const MyToolsScreen()),
                routes: [
                  GoRoute(
                    path: 'add',
                    pageBuilder:
                        slideUpPage((_, __) => const AddToolScreen()),
                  ),
                  GoRoute(
                    path: ':toolId',
                    pageBuilder: slideLeftPage(
                      (_, state) => ToolDetailScreen(
                        toolId: state.pathParameters['toolId']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'edit',
                parentNavigatorKey: null,
                pageBuilder:
                    slideLeftPage((_, __) => const EditProfileScreen()),
              ),
              GoRoute(
                path: 'switch-role',
                pageBuilder:
                    slideLeftPage((_, __) => const RoleSwitcherScreen()),
              ),
              GoRoute(
                path: 'roles',
                pageBuilder:
                    slideLeftPage((_, __) => const RolesScreen()),
                routes: [
                  GoRoute(
                    path: 'switched',
                    pageBuilder: fadePage(
                      (_, state) => RoleSwitchedScreen(
                        role: SystemRole.fromString(
                              state.uri.queryParameters['role'],
                            ) ??
                            SystemRole.customer,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'rep-rights',
                pageBuilder:
                    slideLeftPage((_, __) => const RepRightsScreen()),
              ),
              GoRoute(
                path: 'language',
                pageBuilder:
                    slideLeftPage((_, __) => const LanguageScreen()),
              ),
              GoRoute(
                path: 'notifications',
                pageBuilder: slideLeftPage(
                  (_, __) => const NotificationSettingsScreen(),
                ),
              ),
              GoRoute(
                path: 'help',
                pageBuilder: slideLeftPage((_, __) => const HelpScreen()),
                routes: [
                  GoRoute(
                    path: ':itemId',
                    pageBuilder: slideLeftPage(
                      (_, state) => FaqDetailScreen(
                        itemId: state.pathParameters['itemId']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'feedback',
                pageBuilder:
                    slideLeftPage((_, __) => const FeedbackScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/payments/:paymentId',
        pageBuilder: slideLeftPage(
          (_, state) => PaymentDetailScreen(
            paymentId: state.pathParameters['paymentId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/chats/:chatId',
        pageBuilder: slideLeftPage(
          (_, state) => ChatConversationScreen(
            chatId: state.pathParameters['chatId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: slideUpPage((_, __) => const NotificationsScreen()),
      ),
      GoRoute(
        path: '/documents/:documentId',
        pageBuilder: slideLeftPage(
          (_, state) => DocumentDetailScreen(
            documentId: state.pathParameters['documentId']!,
          ),
        ),
        routes: [
          GoRoute(
            path: 'view',
            pageBuilder: slideUpPage(
              (_, state) => DocumentViewerScreen(
                documentId: state.pathParameters['documentId']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/support',
        pageBuilder: slideLeftPage((_, __) => const SupportContactsScreen()),
      ),
      GoRoute(
        path: '/methodology',
        pageBuilder: slideLeftPage((_, __) => const MethodologyScreen()),
        routes: [
          GoRoute(
            path: 'search',
            pageBuilder:
                fadePage((_, __) => const MethodologySearchScreen()),
          ),
          GoRoute(
            path: 'sections/:sectionId',
            pageBuilder: slideLeftPage(
              (_, state) => MethodologySectionScreen(
                sectionId: state.pathParameters['sectionId']!,
              ),
            ),
          ),
          GoRoute(
            path: 'articles/:articleId',
            pageBuilder: slideLeftPage(
              (_, state) => ArticleScreen(
                articleId: state.pathParameters['articleId']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/knowledge',
        pageBuilder: slideLeftPage(
          (_, state) => KnowledgeScreen(
            moduleSlug: state.uri.queryParameters['moduleSlug'],
          ),
        ),
        routes: [
          GoRoute(
            path: 'search',
            pageBuilder:
                fadePage((_, __) => const KnowledgeSearchScreen()),
          ),
          GoRoute(
            path: 'categories/:categoryId',
            pageBuilder: slideLeftPage(
              (_, state) => KnowledgeCategoryScreen(
                categoryId: state.pathParameters['categoryId']!,
              ),
            ),
          ),
          GoRoute(
            path: 'articles/:articleId',
            pageBuilder: slideLeftPage(
              (_, state) => KnowledgeArticleScreen(
                articleId: state.pathParameters['articleId']!,
              ),
            ),
          ),
        ],
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _sub = _ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (prev?.status != next.status) notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(body: AppLoadingState());
  }
}

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell({required this.child});

  final Widget child;

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  bool _legalChecked = false;

  static const _tabs = [
    _Tab(AppRoutes.projects, Icons.home_outlined, 'Проекты'),
    _Tab(AppRoutes.contractors, Icons.people_outline_rounded, 'Команда'),
    _Tab(AppRoutes.chats, Icons.chat_bubble_outline_rounded, 'Чаты'),
    _Tab(AppRoutes.profile, Icons.person_outline_rounded, 'Профиль'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_legalChecked) {
      _legalChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showPendingLegalAcceptance(context, ref);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => loc.startsWith(t.path));
    final chatUnread = ref.watch(notificationsProvider).where((n) {
      if (n.read) return false;
      return n.kind.startsWith('chat_') || n.kind.startsWith('message_');
    }).length;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: [
          for (final t in _tabs)
            AppBottomNavItem(
              icon: t.icon,
              label: t.label,
              badgeCount: t.path == AppRoutes.chats ? chatUnread : 0,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
