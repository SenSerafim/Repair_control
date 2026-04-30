import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/widgets.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../../stages/domain/traffic_light.dart';
import '../application/project_controller.dart';
import '../domain/project.dart';
import 'card_menu_sheet.dart';

/// s-console-* — главный экран проекта (5 семафор-состояний + done + loading).
///
/// Дизайн `Кластер B`: ConHeader (back + title + bell) + traffic-badge
/// + HouseProgress + StatsRow + BudgetCard + StagesScroll + NavGrid.
class ConsoleScreen extends ConsumerWidget {
  const ConsoleScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectControllerProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.n50,
      body: projectAsync.when(
        loading: () => const _ConsoleSkeleton(),
        error: (e, _) => Center(
          child: AppErrorState(
            title: 'Не удалось загрузить проект',
            onRetry: () =>
                ref.invalidate(projectControllerProvider(projectId)),
          ),
        ),
        data: (project) => _Body(projectId: projectId, project: project),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.projectId, required this.project});

  final String projectId;
  final Project project;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  /// Счётчик закрытых этапов — увеличивается на каждое появление нового
  /// `done`-этапа в стрим-апдейте `stagesControllerProvider`. Передаётся
  /// в `AppHouseProgress.bouncePulse`, который при изменении запускает
  /// 700ms bounce-анимацию.
  int _bouncePulse = 0;

  @override
  void dispose() {
    HouseCelebrationOverlay.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final project = widget.project;

    // 1. Слушаем перевод этапов в done — bouncePulse++ запустит лёгкий
    //    bounce дома без полного WOW.
    ref.listen<AsyncValue<List<Stage>>>(
      stagesControllerProvider(projectId),
      (prev, next) {
        final oldDone = (prev?.value ?? const <Stage>[])
            .where((s) => s.status == StageStatus.done)
            .length;
        final newDone = (next.value ?? const <Stage>[])
            .where((s) => s.status == StageStatus.done)
            .length;
        if (prev != null && newDone > oldDone) {
          setState(() => _bouncePulse++);
        }
      },
    );

    // 2. Слушаем переход progressCache <100 → 100 — запускает WOW-overlay.
    ref.listen<AsyncValue<Project>>(
      projectControllerProvider(projectId),
      (prev, next) {
        final oldP = prev?.value?.progressCache ?? 0;
        final newP = next.value?.progressCache ?? 0;
        if (oldP < 100 && newP >= 100) {
          HouseCelebrationOverlay.show(context);
        }
      },
    );

    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final stages = stagesAsync.value ?? const <Stage>[];
    final canSeeBudget = ref.watch(
      canInProjectProvider((
        action: DomainAction.financeBudgetView,
        projectId: projectId,
      )),
    );
    final unread =
        ref.watch(notificationsProvider).where((n) => !n.read).length;

    final effectiveSemaphore = stages.isEmpty
        ? project.semaphore
        : computeProjectTrafficLight(stages).semaphore;

    final p = stages.isEmpty
        ? project
        : project.copyWith(semaphore: effectiveSemaphore);

    final activeStages = stages.where((s) => s.status == StageStatus.active);
    final doneStages = stages.where((s) => s.status == StageStatus.done);
    final activeStage = activeStages.isEmpty
        ? null
        : activeStages.reduce((a, b) =>
            a.orderIndex < b.orderIndex ? a : b);

    return Column(
      children: [
        _ConHeader(
          project: p,
          unreadNotifications: unread,
          onMenu: () => showCardMenuSheet(context, ref, project: p),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(projectControllerProvider(projectId))
                ..invalidate(stagesControllerProvider(projectId));
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SizedBox(height: AppSpacing.x12),
                _HouseSection(
                  project: p,
                  stages: stages,
                  activeStage: activeStage,
                  doneCount: doneStages.length,
                  bouncePulse: _bouncePulse,
                ),
                if (_bannerFor(p, stages) != null) ...[
                  const SizedBox(height: AppSpacing.x14),
                  _bannerFor(p, stages)!,
                ],
                const SizedBox(height: AppSpacing.x14),
                _StatsRow(project: p, stages: stages),
                if (canSeeBudget) ...[
                  const SizedBox(height: AppSpacing.x12),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
                    child: AppBudgetCard(
                      totalLabel: 'Бюджет проекта',
                      totalValue: '${_formatRubles(p.workBudget + p.materialsBudget)} ₽',
                      workSpent: '0',
                      workTotal: _formatRubles(p.workBudget),
                      materialsSpent: '0',
                      materialsTotal: _formatRubles(p.materialsBudget),
                      onTap: () => context.push('/projects/$projectId/budget'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x16),
                TourAnchor(
                  id: 'console.stages_tile',
                  child: _StagesCarouselHeader(
                    onAllTap: () =>
                        context.push('/projects/$projectId/stages'),
                  ),
                ),
                const SizedBox(height: AppSpacing.x10),
                _StagesCarousel(projectId: projectId, stages: stages),
                const SizedBox(height: AppSpacing.x20),
                _NavSections(projectId: projectId),
                const SizedBox(height: AppSpacing.x24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _bannerFor(Project p, List<Stage> stages) {
    if (p.progressCache >= 100) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: AppConsoleBanner(
          semaphore: Semaphore.green,
          title: 'Проект завершён!',
          subtitle: 'Все этапы закрыты. Можно отправить в архив или '
              'скачать ZIP-сводку.',
        ),
      );
    }
    if (!p.planApproved && p.requiresPlanApproval) {
      return AppConsoleBanner(
        semaphore: Semaphore.blue,
        title: 'План на согласовании',
        subtitle: 'Заказчик ещё не одобрил план этапов. До одобрения '
            'старт работ заблокирован.',
        actionLabel: 'Показать план целиком',
        onAction: () {},
      );
    }
    return switch (p.semaphore) {
      Semaphore.green => null,
      Semaphore.yellow => const AppConsoleBanner(
          semaphore: Semaphore.yellow,
          title: 'Есть отставание',
          subtitle:
              'Часть этапов идёт медленнее плана. Обратите внимание на сроки.',
        ),
      Semaphore.red => const AppConsoleBanner(
          semaphore: Semaphore.red,
          title: 'Есть просрочки',
          subtitle: 'Дедлайн пройден или критическое отставание. '
              'Нужно срочное вмешательство.',
        ),
      Semaphore.blue => const AppConsoleBanner(
          semaphore: Semaphore.blue,
          title: 'Ждёт действия',
          subtitle: 'Этап на приёмке или ждёт согласования. '
              'Видно, чьего хода ждём.',
        ),
      _ => null,
    };
  }

  static String _formatRubles(int kopecks) {
    final rubles = kopecks ~/ 100;
    return NumberFormat.decimalPattern('ru').format(rubles);
  }
}

class _ConHeader extends StatelessWidget {
  const _ConHeader({
    required this.project,
    required this.unreadNotifications,
    required this.onMenu,
  });

  final Project project;
  final int unreadNotifications;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        decoration: const BoxDecoration(
          color: AppColors.n0,
          border:
              Border(bottom: BorderSide(color: AppColors.n200, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _IconShellBtn(
                  icon: PhosphorIconsRegular.caretLeft,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n900,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _IconShellBtn(
                      icon: PhosphorIconsRegular.bell,
                      onTap: () =>
                          context.push(AppRoutes.notifications),
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.redDot,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.n0, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadNotifications > 99
                                ? '99'
                                : '$unreadNotifications',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.n0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                _IconShellBtn(
                  icon: PhosphorIconsRegular.dotsThreeOutline,
                  onTap: onMenu,
                ),
              ],
            ),
            if ((project.address ?? '').isNotEmpty ||
                project.plannedStart != null ||
                project.plannedEnd != null) ...[
              const SizedBox(height: AppSpacing.x10),
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.mapPin,
                    size: 12,
                    color: AppColors.n400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _addrAndDates(project),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.x10),
            Align(
              alignment: Alignment.centerLeft,
              child: _TrafficBadge(semaphore: project.semaphore),
            ),
          ],
        ),
      ),
    );
  }

  static String _addrAndDates(Project p) {
    final df = DateFormat('d MMM yyyy', 'ru');
    final parts = <String>[];
    if ((p.address ?? '').isNotEmpty) parts.add(p.address!);
    if (p.plannedStart != null && p.plannedEnd != null) {
      parts.add(
        '${df.format(p.plannedStart!)} — ${df.format(p.plannedEnd!)}',
      );
    }
    return parts.join(' · ');
  }
}

class _IconShellBtn extends StatelessWidget {
  const _IconShellBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.n200),
            borderRadius: BorderRadius.circular(AppRadius.r12),
            boxShadow: AppShadows.sh1,
          ),
          child: Icon(icon, size: 18, color: AppColors.n600),
        ),
      ),
    );
  }
}

class _TrafficBadge extends StatelessWidget {
  const _TrafficBadge({required this.semaphore});

  final Semaphore semaphore;

  @override
  Widget build(BuildContext context) {
    final label = switch (semaphore) {
      Semaphore.green => 'По графику',
      Semaphore.yellow => 'Отставание',
      Semaphore.red => 'Просрочка',
      Semaphore.blue => 'Ждёт действия',
      _ => 'План',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: semaphore.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: semaphore.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: semaphore.text,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseSection extends StatelessWidget {
  const _HouseSection({
    required this.project,
    required this.stages,
    required this.activeStage,
    required this.doneCount,
    required this.bouncePulse,
  });

  final Project project;
  final List<Stage> stages;
  final Stage? activeStage;
  final int doneCount;
  final int bouncePulse;

  @override
  Widget build(BuildContext context) {
    final total = stages.length;
    final percent = project.progressCache.clamp(0, 100);
    final stageNo = activeStage != null ? activeStage!.orderIndex + 1 : doneCount;
    final statusLabel = switch (project.semaphore) {
      Semaphore.green => 'По графику',
      Semaphore.yellow => 'Отставание',
      Semaphore.red => 'Просрочка',
      Semaphore.blue => 'Ждёт действия',
      _ => 'Планирование',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Column(
        children: [
          AppHouseProgress(
            percent: percent,
            semaphore: project.semaphore,
            size: 220,
            bouncePulse: bouncePulse,
            subtitle: total > 0
                ? 'Этап $stageNo из $total · $statusLabel'
                : 'План пока не построен',
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.project, required this.stages});

  final Project project;
  final List<Stage> stages;

  @override
  Widget build(BuildContext context) {
    // Стат-карточки агрегируют этапы — глубже статистика недоступна на
    // проекте без отдельного запроса /stages/:id/steps. Используем
    // project.progressCache как индикатор прогресса.
    final stageDone = stages.where((s) => s.status == StageStatus.done).length;
    final stageTotal = stages.length;

    final daysToDeadline = project.plannedEnd == null
        ? null
        : project.plannedEnd!.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Row(
        children: [
          Expanded(
            child: AppStatCard(
              label: 'ПРОГРЕСС',
              value: '${project.progressCache}',
              total: '100',
              subtext: '${100 - project.progressCache}% осталось',
              progress: project.progressCache / 100,
              semaphore: project.semaphore,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppStatCard(
              label: 'ДО ДЕДЛАЙНА',
              value: daysToDeadline == null
                  ? '—'
                  : daysToDeadline >= 0
                      ? '$daysToDeadline'
                      : '${-daysToDeadline}',
              subtext: daysToDeadline == null
                  ? 'не задан'
                  : daysToDeadline >= 0
                      ? 'дней'
                      : 'дн просрочено',
              progress: 0.5,
              semaphore: daysToDeadline != null && daysToDeadline < 0
                  ? Semaphore.red
                  : Semaphore.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppStatCard(
              label: 'ЭТАПЫ',
              value: '$stageDone',
              total: '$stageTotal',
              subtext: '${stageTotal - stageDone} в работе',
              progress: stageTotal == 0 ? 0 : stageDone / stageTotal,
              semaphore: project.semaphore,
            ),
          ),
        ],
      ),
    );
  }
}

class _StagesCarouselHeader extends StatelessWidget {
  const _StagesCarouselHeader({required this.onAllTap});

  final VoidCallback onAllTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Этапы проекта',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.n800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAllTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Все этапы',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  PhosphorIconsRegular.arrowRight,
                  size: 12,
                  color: AppColors.brand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StagesCarousel extends StatelessWidget {
  const _StagesCarousel({required this.projectId, required this.stages});

  final String projectId;
  final List<Stage> stages;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            border: Border.all(color: AppColors.n200),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIconsRegular.info,
                size: 16,
                color: AppColors.n400,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Этапов ещё нет — добавьте их, чтобы видеть прогресс',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        itemCount: stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = stages[i];
          return AppStageMiniCard(
            title: s.title,
            statusLabel: _statusLabel(s.status),
            statusKind: _statusKind(s.status),
            assigneeName: s.foremanIds.isEmpty
                ? 'Не назначен'
                : 'Бригадир',
            stepsLabel: '${s.progressCache}% шагов',
            questionsLabel: 'Вопросов нет',
            deadlineLabel: s.plannedEnd != null
                ? 'Срок: ${DateFormat('d MMM', 'ru').format(s.plannedEnd!)}'
                : 'Срок не задан',
            progress: s.progressCache / 100,
            assigneeAlert: s.foremanIds.isEmpty,
            // go_router использует context.push, а не Navigator.pushNamed
            // (у Navigator нет onGenerateRoute → assertion на тапе по этапу).
            onTap: () => context.push('/projects/$projectId/stages/${s.id}'),
          );
        },
      ),
    );
  }

  static String _statusLabel(StageStatus s) => switch (s) {
        StageStatus.pending => 'Не начат',
        StageStatus.active => 'В работе',
        StageStatus.paused => 'Пауза',
        StageStatus.review => 'Приёмка',
        StageStatus.done => 'Завершён',
        StageStatus.rejected => 'Отклонён',
      };

  static AppStageMiniStatus _statusKind(StageStatus s) => switch (s) {
        StageStatus.pending => AppStageMiniStatus.pending,
        StageStatus.active => AppStageMiniStatus.active,
        StageStatus.paused => AppStageMiniStatus.paused,
        StageStatus.review => AppStageMiniStatus.review,
        StageStatus.done => AppStageMiniStatus.done,
        StageStatus.rejected => AppStageMiniStatus.rejected,
      };
}

class _ConsoleSkeleton extends StatelessWidget {
  const _ConsoleSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppSkeletonRow(width: 36, height: 36, radius: 12),
                SizedBox(width: 12),
                Expanded(child: AppSkeletonRow(height: 18)),
                SizedBox(width: 12),
                AppSkeletonRow(width: 36, height: 36, radius: 12),
              ],
            ),
            const SizedBox(height: 24),
            const Center(
              child: AppSkeletonRow(width: 160, height: 130, radius: 80),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: AppSkeletonRow(height: 88, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: AppSkeletonRow(height: 88, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: AppSkeletonRow(height: 88, radius: 12)),
              ],
            ),
            const SizedBox(height: 12),
            const AppSkeletonRow(height: 100, radius: 16),
            const SizedBox(height: 16),
            const AppSkeletonRow(height: 188, radius: 16),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: AppSkeletonRow(height: 78, radius: 16)),
                SizedBox(width: 8),
                Expanded(child: AppSkeletonRow(height: 78, radius: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Группировка нав-плиток консоли по разделам:
/// — «Этапы и работа» (Этапы / Согласования)
/// — «Команда и общение» (Команда / Чаты)
/// — «Финансы» (Бюджет / Материалы / Самозакуп / Инструмент) — role-gated
/// — «Документы и лента» (Заметки / Документы / Лента / Экспорты / Методология)
///
/// Сетка адаптивная: 2 в строку, последняя плитка может быть `wide`.
class _NavSections extends ConsumerWidget {
  const _NavSections({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canBudget = ref.watch(canInProjectProvider((
      action: DomainAction.financeBudgetView,
      projectId: projectId,
    )));
    final canMaterials = ref.watch(canInProjectProvider((
      action: DomainAction.materialsManage,
      projectId: projectId,
    )));
    final canSelfPurchase = ref.watch(canInProjectProvider((
      action: DomainAction.selfPurchaseCreate,
      projectId: projectId,
    )));
    final canTools = ref.watch(canInProjectProvider((
      action: DomainAction.toolsIssue,
      projectId: projectId,
    )));
    final canApprovals = ref.watch(canInProjectProvider((
      action: DomainAction.approvalList,
      projectId: projectId,
    )));
    final canChat = ref.watch(canInProjectProvider((
      action: DomainAction.chatRead,
      projectId: projectId,
    )));

    final stagesAndWork = <AppNavTileSpec>[
      AppNavTileSpec(
        icon: PhosphorIconsFill.lightning,
        iconColor: AppColors.brand,
        label: 'Этапы',
        onTap: () => context.push('/projects/$projectId/stages'),
      ),
      if (canApprovals)
        AppNavTileSpec(
          icon: PhosphorIconsFill.checkSquare,
          iconColor: AppColors.purple,
          label: 'Согласования',
          onTap: () => context.push('/projects/$projectId/approvals'),
        ),
    ];

    final teamAndChat = <AppNavTileSpec>[
      AppNavTileSpec(
        icon: PhosphorIconsFill.usersThree,
        iconColor: AppColors.greenDark,
        label: 'Команда',
        onTap: () => context.push('/projects/$projectId/team'),
      ),
      if (canChat)
        AppNavTileSpec(
          icon: PhosphorIconsFill.chatCircleDots,
          iconColor: AppColors.brand,
          label: 'Чаты проекта',
          onTap: () => context.push('/projects/$projectId/chats'),
        ),
    ];

    final finance = <AppNavTileSpec>[
      if (canBudget)
        AppNavTileSpec(
          icon: PhosphorIconsFill.wallet,
          iconColor: AppColors.greenDark,
          label: 'Бюджет',
          onTap: () => context.push('/projects/$projectId/budget'),
        ),
      if (canMaterials)
        AppNavTileSpec(
          icon: PhosphorIconsFill.package,
          iconColor: AppColors.yellowText,
          label: 'Материалы',
          onTap: () => context.push('/projects/$projectId/materials'),
        ),
      if (canSelfPurchase)
        AppNavTileSpec(
          icon: PhosphorIconsFill.basket,
          iconColor: AppColors.brand,
          label: 'Самозакуп',
          onTap: () =>
              context.push('/projects/$projectId/selfpurchases'),
        ),
      if (canTools)
        AppNavTileSpec(
          icon: PhosphorIconsFill.wrench,
          iconColor: AppColors.n700,
          label: 'Инструмент',
          onTap: () => context.push('/projects/$projectId/tools'),
        ),
    ];

    final docsAndFeed = <AppNavTileSpec>[
      AppNavTileSpec(
        icon: PhosphorIconsFill.notepad,
        iconColor: AppColors.brand,
        label: 'Заметки',
        onTap: () => context.push('/projects/$projectId/notes'),
      ),
      AppNavTileSpec(
        icon: PhosphorIconsFill.fileText,
        iconColor: AppColors.n700,
        label: 'Документы',
        onTap: () => context.push('/projects/$projectId/documents'),
      ),
      AppNavTileSpec(
        icon: PhosphorIconsFill.flowArrow,
        iconColor: AppColors.greenDark,
        label: 'Лента',
        onTap: () => context.push('/projects/$projectId/feed'),
      ),
      AppNavTileSpec(
        icon: PhosphorIconsFill.downloadSimple,
        iconColor: AppColors.purple,
        label: 'Экспорты',
        onTap: () => context.push('/projects/$projectId/exports'),
      ),
      AppNavTileSpec(
        icon: PhosphorIconsFill.bookOpen,
        iconColor: AppColors.brand,
        label: 'Справка',
        onTap: () => context.push(AppRoutes.knowledgeWithModule('console')),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stagesAndWork.isNotEmpty) ...[
            const _NavSectionLabel('ЭТАПЫ И РАБОТА'),
            const SizedBox(height: AppSpacing.x8),
            AppNavTileGrid(tiles: stagesAndWork),
            const SizedBox(height: AppSpacing.x16),
          ],
          if (teamAndChat.isNotEmpty) ...[
            const _NavSectionLabel('КОМАНДА И ОБЩЕНИЕ'),
            const SizedBox(height: AppSpacing.x8),
            AppNavTileGrid(tiles: teamAndChat),
            const SizedBox(height: AppSpacing.x16),
          ],
          if (finance.isNotEmpty) ...[
            const _NavSectionLabel('ФИНАНСЫ И ЗАКУПКИ'),
            const SizedBox(height: AppSpacing.x8),
            AppNavTileGrid(tiles: finance),
            const SizedBox(height: AppSpacing.x16),
          ],
          const _NavSectionLabel('ДОКУМЕНТЫ И ИСТОРИЯ'),
          const SizedBox(height: AppSpacing.x8),
          AppNavTileGrid(tiles: docsAndFeed),
        ],
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  const _NavSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.n400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
