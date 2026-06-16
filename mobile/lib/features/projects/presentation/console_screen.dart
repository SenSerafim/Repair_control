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
import '../../approvals/application/approvals_controller.dart';
import '../../chat/application/chats_controller.dart';
import '../../finance/application/budget_controller.dart';
import '../../finance/domain/budget.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../../stages/domain/stage_status_filter.dart';
import '../../stages/domain/traffic_light.dart';
import '../../team/application/team_controller.dart';
import '../domain/membership.dart';
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
            onRetry: () => ref.invalidate(projectControllerProvider(projectId)),
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

  /// Task 5.4 — фильтр-чипы над каруселью этапов (ТЗ-фронт §4).
  /// Дефолт «Все» — карусель показывает все этапы как и раньше.
  StageStatusFilter _stageFilter = StageStatusFilter.all;

  /// Task 5.5 — collapse-toggle для иллюстрации `AppHouseProgress`.
  /// Дефолт = развёрнуто. Без персиста между сессиями (scope creep —
  /// см. план §5.5: persistence помечен как nice-to-have).
  bool _houseCollapsed = false;

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
    ref.listen<AsyncValue<List<Stage>>>(stagesControllerProvider(projectId), (
      prev,
      next,
    ) {
      final oldDone = (prev?.value ?? const <Stage>[])
          .where((s) => s.status == StageStatus.done)
          .length;
      final newDone = (next.value ?? const <Stage>[])
          .where((s) => s.status == StageStatus.done)
          .length;
      if (prev != null && newDone > oldDone) {
        setState(() => _bouncePulse++);
      }
    });

    // 2. Слушаем переход progressCache <100 → 100 — запускает WOW-overlay.
    ref.listen<AsyncValue<Project>>(projectControllerProvider(projectId), (
      prev,
      next,
    ) {
      final oldP = prev?.value?.progressCache ?? 0;
      final newP = next.value?.progressCache ?? 0;
      if (oldP < 100 && newP >= 100) {
        HouseCelebrationOverlay.show(context);
      }
    });

    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final stages = stagesAsync.value ?? const <Stage>[];
    final canSeeBudget = ref.watch(
      canInProjectProvider((
        action: DomainAction.financeBudgetView,
        projectId: projectId,
      )),
    );
    final canInviteMember = ref.watch(
      canInProjectProvider((
        action: DomainAction.projectInviteMember,
        projectId: projectId,
      )),
    );
    final unread = ref
        .watch(notificationsProvider)
        .where((n) => !n.read)
        .length;

    final effectiveSemaphore = stages.isEmpty
        ? project.effectiveSemaphore
        : computeProjectTrafficLight(stages).semaphore;

    final p = stages.isEmpty
        ? project
        : project.copyWith(semaphore: effectiveSemaphore);

    final activeStages = stages.where((s) => s.status == StageStatus.active);
    final doneStages = stages.where((s) => s.status == StageStatus.done);
    final activeStage = activeStages.isEmpty
        ? null
        : activeStages.reduce((a, b) => a.orderIndex < b.orderIndex ? a : b);

    return Column(
      children: [
        _ConHeader(
          project: p,
          unreadNotifications: unread,
          canInviteMember: canInviteMember,
          onAddMember: () => context.push('/projects/$projectId/team'),
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
                  collapsed: _houseCollapsed,
                  onToggleCollapsed: () =>
                      setState(() => _houseCollapsed = !_houseCollapsed),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x16,
                    ),
                    child: _BudgetSlot(project: p, projectId: projectId),
                  ),
                ],
                const SizedBox(height: AppSpacing.x16),
                TourAnchor(
                  id: 'console.stages_tile',
                  child: _StagesCarouselHeader(
                    onAllTap: () => context.push('/projects/$projectId/stages'),
                  ),
                ),
                // Task 5.4 — фильтр-чипы над каруселью (ТЗ-фронт §4).
                // Ровно 5 значений: Все · В работе · На согласовании ·
                // На паузе · Без бригадира. Маппинг:
                // «На согласовании» → `pending` (включает computed
                // lateStart). Использует общий `AppFilterPillBar` +
                // публичный `StageStatusFilter` (см.
                // `domain/stage_status_filter.dart`).
                _StagesFilterBar(
                  active: _stageFilter,
                  onSelect: (f) => setState(() => _stageFilter = f),
                ),
                _StagesCarousel(
                  projectId: projectId,
                  stages: stages.where(_stageFilter.match).toList(),
                ),
                const SizedBox(height: AppSpacing.x20),
                // ТЗ NEWFIX §1.1: блок быстрых кнопок под списком этапов —
                // Команда / Согласования (badge) / Чаты (badge) / Заявки.
                _ProjectQuickActions(projectId: projectId),
                const SizedBox(height: AppSpacing.x16),
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
          subtitle:
              'Все этапы закрыты. Можно отправить в архив или '
              'скачать ZIP-сводку.',
        ),
      );
    }
    if (!p.planApproved && p.requiresPlanApproval) {
      return AppConsoleBanner(
        semaphore: Semaphore.blue,
        title: 'План на согласовании',
        subtitle:
            'Заказчик ещё не одобрил план этапов. До одобрения '
            'старт работ заблокирован.',
        actionLabel: 'Показать план целиком',
        // Раньше onAction был no-op — кнопка казалась рабочей, но ничего
        // не делала. Шлём на глобальный список согласований, отфильтрованный
        // по этому проекту его scope.
        onAction: () => context.push(AppRoutes.approvals),
      );
    }
    return switch (p.effectiveSemaphore) {
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
        subtitle:
            'Дедлайн пройден или критическое отставание. '
            'Нужно срочное вмешательство.',
      ),
      Semaphore.blue => const AppConsoleBanner(
        semaphore: Semaphore.blue,
        title: 'Ждёт действия',
        subtitle:
            'Этап на приёмке или ждёт согласования. '
            'Видно, чьего хода ждём.',
      ),
      Semaphore.paused => const AppConsoleBanner(
        semaphore: Semaphore.paused,
        title: 'Работы заблокированы',
        subtitle:
            'Дедлайн проекта прошёл, а план ещё не согласован. '
            'Бригадир ждёт решения заказчика.',
      ),
      _ => null,
    };
  }
}

class _ConHeader extends StatelessWidget {
  const _ConHeader({
    required this.project,
    required this.unreadNotifications,
    required this.canInviteMember,
    required this.onAddMember,
    required this.onMenu,
  });

  final Project project;
  final int unreadNotifications;
  final bool canInviteMember;
  final VoidCallback onAddMember;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        decoration: const BoxDecoration(
          color: AppColors.n0,
          border: Border(bottom: BorderSide(color: AppColors.n200, width: 1)),
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
                if (canInviteMember) ...[
                  _IconShellBtn(
                    icon: PhosphorIconsRegular.plus,
                    onTap: onAddMember,
                  ),
                  const SizedBox(width: 4),
                ],
                // NEWFIX-2 §19 — иконка «Заметки проекта» переехала на
                // карточку проекта в списке (ProjectCard). В шапке консоли
                // её больше нет — экран «Заметки» доступен с карточки и
                // через кнопку «Все заметки проекта» из quick-note sheet.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _IconShellBtn(
                      icon: PhosphorIconsRegular.bell,
                      onTap: () => context.push(AppRoutes.notifications),
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.redDot,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.n0, width: 2),
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
              child: _TrafficBadge(
                semaphore: project.effectiveSemaphore,
                delta: _deltaFor(project),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Дельта дней рядом со статусом: «−6 дн» / «+8 дн». Возвращаем `null`,
  /// если для текущего semaphore дельта не имеет смысла (например, для
  /// `green/plan/blue` мы её не показываем — дизайн рисует пустой бейдж).
  static String? _deltaFor(Project p) {
    final end = p.plannedEnd;
    if (end == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(end.year, end.month, end.day);
    final diff = today.difference(due).inDays;
    return switch (p.effectiveSemaphore) {
      Semaphore.red when diff > 0 => '+$diff ${_dayWord(diff)}',
      Semaphore.yellow when diff < 0 => '$diff ${_dayWord(-diff)}',
      _ => null,
    };
  }

  static String _dayWord(int n) {
    final mod10 = n.abs() % 10;
    final mod100 = n.abs() % 100;
    if (mod10 == 1 && mod100 != 11) return 'дн';
    return 'дн';
  }

  static String _addrAndDates(Project p) {
    final df = DateFormat('d MMM yyyy', 'ru');
    final parts = <String>[];
    if ((p.address ?? '').isNotEmpty) parts.add(p.address!);
    if (p.plannedStart != null && p.plannedEnd != null) {
      parts.add('${df.format(p.plannedStart!)} — ${df.format(p.plannedEnd!)}');
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
  const _TrafficBadge({required this.semaphore, this.delta});

  final Semaphore semaphore;

  /// «−6 дн» / «+8 дн» рядом с лейблом для yellow/red (см. HTML
  /// `.chip-warn`/`.tlabel-yellow` с дельтой). null — дельта не нужна.
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final label = switch (semaphore) {
      Semaphore.green => 'По графику',
      Semaphore.yellow => 'Отставание',
      Semaphore.red => 'Просрочка',
      Semaphore.blue => 'Ждёт действия',
      Semaphore.paused => 'На паузе',
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
          if (delta != null) ...[
            const SizedBox(width: 6),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: semaphore.text.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              delta!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: semaphore.text,
              ),
            ),
          ],
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
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final Project project;
  final List<Stage> stages;
  final Stage? activeStage;
  final int doneCount;
  final int bouncePulse;

  /// Task 5.5 — свернуть/развернуть иллюстрацию дома. Кнопка-«шеврон»
  /// рядом со статус-меткой; персиста между сессиями нет (см. план).
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final total = stages.length;
    final percent = project.progressCache.clamp(0, 100);
    final stageNo = activeStage != null
        ? activeStage!.orderIndex + 1
        : doneCount;
    final statusLabel = switch (project.effectiveSemaphore) {
      Semaphore.green => 'По графику',
      Semaphore.yellow => 'Отставание',
      Semaphore.red => 'Просрочка',
      Semaphore.blue => 'Ждёт действия',
      Semaphore.paused => 'На паузе',
      _ => 'Планирование',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Шапка-«пилюля» с подписью прогресса и кнопкой-шевроном.
          // В collapsed-режиме это единственное, что остаётся от секции
          // — пользователь видит статус и при желании разворачивает дом.
          _HouseToggleRow(
            percent: percent,
            stageNo: stageNo,
            total: total,
            statusLabel: statusLabel,
            collapsed: collapsed,
            onTap: onToggleCollapsed,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: collapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x8),
              child: Column(
                children: [
                  AppHouseProgress(
                    percent: percent,
                    semaphore: project.effectiveSemaphore,
                    size: 220,
                    bouncePulse: bouncePulse,
                    subtitle: total > 0
                        ? 'Этап $stageNo из $total · $statusLabel'
                        : 'План пока не построен',
                  ),
                  if (percent == 0) ...[
                    const SizedBox(height: AppSpacing.x12),
                    const _HouseGrowsHint(),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// Маленький «pill»-ряд над иллюстрацией: статус слева + chevron-кнопка
/// справа, нажатие переключает collapsed-режим. Сам дом скрывается
/// `AnimatedCrossFade` — этот ряд остаётся всегда, чтобы пользователь
/// не терял точку взаимодействия.
class _HouseToggleRow extends StatelessWidget {
  const _HouseToggleRow({
    required this.percent,
    required this.stageNo,
    required this.total,
    required this.statusLabel,
    required this.collapsed,
    required this.onTap,
  });

  final int percent;
  final int stageNo;
  final int total;
  final String statusLabel;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final caption = total > 0
        ? 'Прогресс $percent% · этап $stageNo из $total · $statusLabel'
        : 'Прогресс $percent% · план пока не построен';
    return Row(
      children: [
        Expanded(
          child: Text(
            caption,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.n500,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: collapsed ? 'Развернуть' : 'Свернуть',
          icon: Icon(
            collapsed
                ? PhosphorIconsRegular.caretDown
                : PhosphorIconsRegular.caretUp,
            size: 18,
            color: AppColors.n600,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onTap,
        ),
      ],
    );
  }
}

/// Подсказка-«пилюля» под пустым контуром дома: появляется только когда
/// прогресс 0% — объясняет, что дом начнёт «достраиваться» по мере
/// закрытия этапов. Мягкий brand-фон + домик-иконка вместо безликого
/// «0% Этап 0 из 4 · Планирование» (UX-feedback заказчика).
class _HouseGrowsHint extends StatelessWidget {
  const _HouseGrowsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F8FF), AppColors.brandLight],
        ),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.n0,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              PhosphorIconsFill.house,
              size: 16,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Дом будет достраиваться\nпо мере выполнения этапов',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
                height: 1.35,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Бюджет проекта — берёт фактические траты из projectBudgetProvider.
/// Пока данные не пришли — показывает skeleton, чтобы не отображать
/// «0 ₽ потрачено» как факт (раньше это было захардкожено).
class _BudgetSlot extends ConsumerWidget {
  const _BudgetSlot({required this.project, required this.projectId});

  final Project project;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectBudgetProvider(projectId));
    final workTotal = _formatRubles(project.workBudget);
    final materialsTotal = _formatRubles(project.materialsBudget);
    final totalValue =
        '${_formatRubles(project.workBudget + project.materialsBudget)} ₽';

    return async.when(
      data: (ProjectBudget b) => AppBudgetCard(
        totalLabel: 'Бюджет проекта',
        totalValue: totalValue,
        workSpent: _formatRubles(b.work.spent),
        workTotal: workTotal,
        materialsSpent: _formatRubles(b.materials.spent),
        materialsTotal: materialsTotal,
        onTap: () => context.push('/projects/$projectId/budget'),
      ),
      loading: () => const AppSkeletonRow(height: 132, radius: 16),
      // Если факты недоступны — рисуем карточку с прочерками вместо вранья
      // «потрачено 0 ₽». Тап остаётся живым — пользователь увидит детали.
      error: (_, __) => AppBudgetCard(
        totalLabel: 'Бюджет проекта',
        totalValue: totalValue,
        workSpent: '—',
        workTotal: workTotal,
        materialsSpent: '—',
        materialsTotal: materialsTotal,
        onTap: () => context.push('/projects/$projectId/budget'),
      ),
    );
  }

  static String _formatRubles(int kopecks) {
    final rubles = kopecks ~/ 100;
    return NumberFormat.decimalPattern('ru').format(rubles);
  }
}

/// 0..1 — какая доля периода старт→дедлайн уже прошла. NaN-guard:
/// без plannedStart/plannedEnd возвращаем 0. После дедлайна — 1 (бар
/// заполнен полностью, цвет StatCard сам переключится на red).
double _deadlineProgress(DateTime? start, DateTime? end) {
  if (start == null || end == null) return 0;
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final total = e.difference(s).inDays;
  if (total <= 0) return today.isBefore(e) ? 0 : 1;
  final passed = today.difference(s).inDays;
  if (passed <= 0) return 0;
  if (passed >= total) return 1;
  return passed / total;
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
    // «В работе» = только реально запущенные: active / paused / review.
    // pending = «Не начат» и не должен попадать в этот счётчик.
    final stageInProgress = stages
        .where(
          (s) =>
              s.status == StageStatus.active ||
              s.status == StageStatus.paused ||
              s.status == StageStatus.review,
        )
        .length;

    final daysToDeadline = project.plannedEnd == null
        ? null
        : project.plannedEnd!.difference(DateTime.now()).inDays;
    // Доля прошедшего периода для индикатора «До дедлайна». Раньше было
    // захардкожено 0.5 (всегда «середина»), теперь считаем календарными
    // днями: 0 — старт ещё впереди, 1 — дедлайн пройден.
    final deadlineProgress = _deadlineProgress(
      project.plannedStart,
      project.plannedEnd,
    );

    // Task 5.3 — карточка «ПРОГРЕСС» убрана: процент проекта уже виден
    // на иллюстрации `AppHouseProgress` выше и в прогресс-баре каждого
    // этапа в карусели. На stats-row остаются только «ДО ДЕДЛАЙНА» и
    // «ЭТАПЫ» — две независимые от прогресса метрики.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Row(
        children: [
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
              progress: deadlineProgress,
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
              subtext: '$stageInProgress в работе',
              progress: stageTotal == 0 ? 0 : stageDone / stageTotal,
              semaphore: project.effectiveSemaphore,
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

/// Task 5.4 — фильтр-чипы над каруселью этапов на главной консоли.
///
/// 5 чипов из ТЗ-фронт §4: Все · В работе · На согласовании · На паузе
/// · Без бригадира. Использует общий `AppFilterPillBar` (Cluster F) +
/// доменный [StageStatusFilter] для маппинга предикатов. Маппинг чипа
/// «На согласовании» → `StageStatusFilter.pending` (включая computed
/// `lateStart`): на консоли «pending»-этапы — это именно те, что ждут
/// согласования / старта.
class _StagesFilterBar extends StatelessWidget {
  const _StagesFilterBar({required this.active, required this.onSelect});

  final StageStatusFilter active;
  final ValueChanged<StageStatusFilter> onSelect;

  /// Видимые на консоли чипы (5 шт). `pending` мапится на «На согласовании»
  /// — это решение consola-уровня, оно отличается от полного экрана
  /// `stages_screen.dart`, где это «Ожидает».
  static const _chips = <(StageStatusFilter, String)>[
    (StageStatusFilter.all, 'Все'),
    (StageStatusFilter.active, 'В работе'),
    (StageStatusFilter.pending, 'На согласовании'),
    (StageStatusFilter.paused, 'На паузе'),
    (StageStatusFilter.noContractor, 'Без бригадира'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppFilterPillBar(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x10,
        AppSpacing.x16,
        AppSpacing.x10,
      ),
      activeId: active.name,
      chips: [
        for (final (f, label) in _chips)
          AppFilterPillSpec(id: f.name, label: label),
      ],
      onSelect: (id) {
        for (final (f, _) in _chips) {
          if (f.name == id) {
            onSelect(f);
            return;
          }
        }
      },
    );
  }
}

class _StagesCarousel extends ConsumerWidget {
  const _StagesCarousel({required this.projectId, required this.stages});

  final String projectId;
  final List<Stage> stages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.n400),
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
            assigneeName: _assigneeNameFor(ref, s),
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

  /// «Фамилия И.» бригадира этапа. Раньше было захардкожено «Бригадир» —
  /// не давало понять, чей этап. Берём первого foreman из foremanIds,
  /// мапим в участники проекта (teamControllerProvider) и режем имя до
  /// «Иванов И.». Если списка ещё нет — fallback «Бригадир».
  String _assigneeNameFor(WidgetRef ref, Stage s) {
    if (s.foremanIds.isEmpty) return 'Не назначен';
    final foremanId = s.foremanIds.first;
    final team = ref.watch(teamControllerProvider(projectId)).value;
    if (team == null) return 'Бригадир';
    Membership? m;
    for (final x in team.members) {
      if (x.userId == foremanId) {
        m = x;
        break;
      }
    }
    final u = m?.user;
    if (u == null) return 'Бригадир';
    final initial = u.firstName.isEmpty ? '' : '${u.firstName[0]}.';
    return [u.lastName, initial].where((p) => p.isNotEmpty).join(' ');
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
/// — «Документы и лента» (Документы / Лента / Методология) — без «Экспорты»
///   (NEWFIX-2 §14.3) и без «Заметки» (§11.6, вход в шапке).
///
/// Сетка адаптивная: 2 в строку, последняя плитка может быть `wide`.
class _NavSections extends ConsumerWidget {
  const _NavSections({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canBudget = ref.watch(
      canInProjectProvider((
        action: DomainAction.financeBudgetView,
        projectId: projectId,
      )),
    );
    // canMaterials остался полезен для _ProjectQuickActions; в _NavSections
    // плитка «Материалы»/«Заявки» больше не рисуется (см. ниже комментарий).
    final canSelfPurchase = ref.watch(
      canInProjectProvider((
        action: DomainAction.selfPurchaseCreate,
        projectId: projectId,
      )),
    );
    // Self-custody модель (2026-05-12): единая плитка «Инструмент» для всех
    // ролей. Любой member видит доску инструментов проекта, может добавить
    // свой или self-claim. Никто не назначает инструмент другому.
    final canTools = ref.watch(
      canInProjectProvider((
        action: DomainAction.toolsViewProject,
        projectId: projectId,
      )),
    );
    final toolsRoute = '/projects/$projectId/tools';
    // ТЗ NEWFIX §1.1: «Этапы» дублирует карусель выше — убираем; «Команда /
    // Согласования / Чаты / Заявки» переехали в _ProjectQuickActions.
    // Здесь оставляем только финансы/документы/ленту/инструмент.
    final stagesAndWork = <AppNavTileSpec>[];
    final teamAndChat = <AppNavTileSpec>[];

    final finance = <AppNavTileSpec>[
      if (canBudget)
        AppNavTileSpec(
          icon: PhosphorIconsFill.wallet,
          iconColor: AppColors.greenDark,
          label: 'Бюджет',
          onTap: () => context.push('/projects/$projectId/budget'),
        ),
      // ТЗ NEWFIX §1.1: «Материалы» → «Заявки», переехали в _ProjectQuickActions.
      // Здесь плитку не дублируем.
      if (canSelfPurchase)
        AppNavTileSpec(
          icon: PhosphorIconsFill.basket,
          iconColor: AppColors.brand,
          label: 'Самозакуп',
          onTap: () => context.push('/projects/$projectId/selfpurchases'),
        ),
      if (canTools)
        AppNavTileSpec(
          icon: PhosphorIconsFill.wrench,
          iconColor: AppColors.n700,
          label: 'Инструмент',
          onTap: () => context.push(toolsRoute),
        ),
    ];

    final docsAndFeed = <AppNavTileSpec>[
      // NEWFIX-2 §11.6 — плитка «Заметки» убрана: вход теперь через иконку
      // в шапке проекта, дублирование в NavGrid не нужно.
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
      // NEWFIX-2 §14.3 — глобальную плитку «Экспорты» убрали. Экспорт PDF
      // теперь делается прямо внутри Заявок (§5.3), Ленты (§12.4) и
      // Документов (§13.1), а не отдельной кнопкой на карточке проекта.
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

/// ТЗ NEWFIX §1.1 — 4 быстрых кнопки под списком этапов.
/// Команда / Согласования / Чаты / Заявки. На «Согл.» и «Чаты» — бейджи
/// с числом непрочитанных/незакрытых. RBAC: согласования/чаты/заявки
/// видны только по соответствующим правам в проекте.
class _ProjectQuickActions extends ConsumerWidget {
  const _ProjectQuickActions({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canApprovals = ref.watch(
      canInProjectProvider((
        action: DomainAction.approvalList,
        projectId: projectId,
      )),
    );
    final canChat = ref.watch(
      canInProjectProvider((
        action: DomainAction.chatRead,
        projectId: projectId,
      )),
    );
    final canMaterials = ref.watch(
      canInProjectProvider((
        action: DomainAction.materialsManage,
        projectId: projectId,
      )),
    );

    // Бейдж согласований — кол-во pending. approvalsControllerProvider
    // и так загружается на экране согласований; здесь watch'им тот же
    // family — провайдер сам подтянет если ещё не был запрошен.
    final approvalsAsync = ref.watch(approvalsControllerProvider(projectId));
    final pendingApprovals = approvalsAsync.maybeWhen(
      data: (b) => b.pending.length,
      orElse: () => 0,
    );

    // Бейдж чатов — сумма unread по всем чатам проекта.
    final chatsAsync = ref.watch(projectChatsProvider(projectId));
    final unreadChats = chatsAsync.maybeWhen(
      data: (chats) => chats.fold<int>(0, (sum, c) => sum + c.unreadCount),
      orElse: () => 0,
    );

    final actions = <_QuickAction>[
      _QuickAction(
        icon: PhosphorIconsFill.usersThree,
        color: AppColors.greenDark,
        label: 'Команда',
        onTap: () => context.push('/projects/$projectId/team'),
      ),
      if (canApprovals)
        _QuickAction(
          icon: PhosphorIconsFill.checkSquare,
          color: AppColors.purple,
          label: 'Согл.',
          badge: pendingApprovals,
          onTap: () => context.push('/projects/$projectId/approvals'),
        ),
      if (canChat)
        _QuickAction(
          icon: PhosphorIconsFill.chatCircleDots,
          color: AppColors.brand,
          label: 'Чаты',
          badge: unreadChats,
          onTap: () => context.push('/projects/$projectId/chats'),
        ),
      if (canMaterials)
        _QuickAction(
          icon: PhosphorIconsFill.package,
          color: AppColors.yellowText,
          label: 'Заявки',
          onTap: () => context.push('/projects/$projectId/materials'),
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.x10,
      crossAxisSpacing: AppSpacing.x10,
      childAspectRatio: 3.0,
      children: [for (final a in actions) _QuickActionTile(action: a)],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final int badge;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x10,
        ),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.n200, width: 1.5),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20),
                ),
                if (action.badge > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.redDot,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        action.badge > 99 ? '99+' : '${action.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                action.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
