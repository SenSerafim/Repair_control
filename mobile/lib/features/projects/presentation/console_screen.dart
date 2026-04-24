import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../application/project_controller.dart';
import '../domain/project.dart';
import 'card_menu_sheet.dart';
import 'console_widgets.dart';

/// ConsoleScreen — главный экран проекта (5 состояний: plan/green/yellow/
/// red/blue + done + loading). Соответствует s-console-* из кластера B.
class ConsoleScreen extends ConsumerWidget {
  const ConsoleScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectControllerProvider(projectId));
    final stagesAsync = ref.watch(stagesControllerProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Консоль',
      padding: EdgeInsets.zero,
      actions: [
        projectAsync.whenOrNull(
              data: (project) => IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () =>
                    showCardMenuSheet(context, ref, project: project),
              ),
            ) ??
            const SizedBox.shrink(),
      ],
      body: projectAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить проект',
          onRetry: () =>
              ref.invalidate(projectControllerProvider(projectId)),
        ),
        data: (project) {
          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(projectControllerProvider(projectId))
                ..invalidate(stagesControllerProvider(projectId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Hero(
                  tag: 'project-${project.id}',
                  flightShuttleBuilder: (ctx, anim, dir, fromCtx, toCtx) {
                    final fromHero = fromCtx.widget as Hero;
                    return fromHero.child;
                  },
                  child: const SizedBox(height: 1),
                ),
                _Header(project: project),
                const SizedBox(height: AppSpacing.x16),
                _HouseAndStats(
                  project: project,
                  stages: stagesAsync.value ?? const [],
                ),
                const SizedBox(height: AppSpacing.x20),
                ..._bannerFor(context, project),
                const SizedBox(height: AppSpacing.x16),
                const Text('Этапы', style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.x10),
                _StagesCarousel(stages: stagesAsync),
                const SizedBox(height: AppSpacing.x20),
                const Text('Разделы', style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.x10),
                _NavGrid(projectId: project.id),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _bannerFor(BuildContext context, Project p) {
    switch (p.semaphore) {
      case Semaphore.plan:
        return [
          ConsoleBanner(
            icon: Icons.schedule_outlined,
            title: 'План не согласован',
            subtitle: p.requiresPlanApproval
                ? 'Отправьте план этапов на согласование заказчику.'
                : 'Добавьте этапы, затем можно начинать работы.',
            color: AppColors.n500,
            actionLabel: p.requiresPlanApproval
                ? 'Отправить план (S13)'
                : null,
            onAction: p.requiresPlanApproval
                ? () => AppToast.show(
                      context,
                      message:
                          'Согласования доступны в Sprint 13.',
                    )
                : null,
          ),
        ];
      case Semaphore.green:
        return const [
          ConsoleBanner(
            icon: Icons.check_circle_outline,
            title: 'Всё по графику',
            subtitle: 'Этапы идут в сроки, проблем нет.',
            color: AppColors.greenDark,
          ),
        ];
      case Semaphore.yellow:
        return const [
          ConsoleBanner(
            icon: Icons.warning_amber_rounded,
            title: 'Есть отставания',
            subtitle: 'Некоторые этапы идут медленнее плана — обратите '
                'внимание на сроки.',
            color: AppColors.yellowDot,
          ),
        ];
      case Semaphore.red:
        return const [
          ConsoleBanner(
            icon: Icons.error_outline,
            title: 'Есть просрочки',
            subtitle: 'Дедлайн этапа прошёл. Нужно решить: перенести '
                'срок или ускорить.',
            color: AppColors.redDot,
          ),
        ];
      case Semaphore.blue:
        return [
          ConsoleBanner(
            icon: Icons.pending_actions_outlined,
            title: 'Ждут согласования',
            subtitle: 'Есть запросы на согласование или смену дедлайна.',
            color: AppColors.blueDot,
            actionLabel: 'Открыть согласования (S13)',
            onAction: () => AppToast.show(
              context,
              message: 'Экран согласований появится в Sprint 13.',
            ),
          ),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.title, style: AppTextStyles.h1, maxLines: 2),
          const SizedBox(height: AppSpacing.x6),
          if (project.addressLine().isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: AppColors.n400,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    project.addressLine(),
                    style: AppTextStyles.caption,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.x12),
          BigTrafficBadge(
            semaphore: project.semaphore,
            label: project.semaphoreLabel,
          ),
        ],
      ),
    );
  }
}

class _HouseAndStats extends StatelessWidget {
  const _HouseAndStats({required this.project, required this.stages});

  final Project project;
  final List<Stage> stages;

  @override
  Widget build(BuildContext context) {
    final total = stages.length;
    final done = stages.where((s) => s.status == StageStatus.done).length;
    final active = stages.indexWhere((s) => s.status == StageStatus.active);
    final stageLabel = total == 0
        ? 'Этапы пока не добавлены'
        : active >= 0
            ? 'Этап ${active + 1} из $total · ${project.semaphoreLabel}'
            : 'Готово $done из $total';

    final daysLeft = _daysLeft(project.plannedEnd);
    final budget = project.totalBudget;

    return Column(
      children: [
        Center(
          child: AppHouseProgress(
            percent: project.progressCache,
            semaphore: project.semaphore,
            subtitle: stageLabel,
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Этапы',
                value: '$done',
                suffix: '/$total',
                hint: total == 0
                    ? 'Добавьте в S11'
                    : '${total - done} осталось',
                progress: total == 0 ? 0 : done / total,
                progressColor: project.semaphore.dot,
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: StatCard(
                label: 'До дедлайна',
                value: daysLeft == null ? '—' : '${daysLeft.abs()}',
                suffix: daysLeft == null
                    ? null
                    : daysLeft >= 0
                        ? ' дн.'
                        : ' дн. просрочено',
                hint: project.plannedEnd == null
                    ? 'Дата не задана'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x10),
        StatCard(
          label: 'Бюджет',
          value: Money.format(budget),
          hint: 'Работы + материалы',
          progress: null,
        ),
      ],
    );
  }

  int? _daysLeft(DateTime? end) {
    if (end == null) return null;
    final now = DateTime.now();
    return end.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}

class _StagesCarousel extends StatelessWidget {
  const _StagesCarousel({required this.stages});

  final AsyncValue<List<Stage>> stages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: stages.when(
        loading: () => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => const Center(
          child: Text(
            'Не удалось загрузить этапы',
            style: AppTextStyles.caption,
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.x16),
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: AppRadius.card,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    color: AppColors.n400,
                  ),
                  SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Text(
                      'Пока нет этапов. Добавьте в Sprint 11.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.x10),
            itemBuilder: (_, i) {
              final s = items[i];
              return StagePreviewCard(
                index: i + 1,
                title: s.title,
                semaphore: s.status.semaphore,
                progress: s.progressCache,
              );
            },
          );
        },
      ),
    );
  }
}

class _NavGrid extends StatelessWidget {
  const _NavGrid({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final tiles = <_NavTileSpec>[
      _NavTileSpec(
        icon: Icons.dashboard_outlined,
        label: 'Этапы',
        onTap: () => context.push('/projects/$projectId/stages'),
      ),
      _NavTileSpec(
        icon: Icons.people_outline_rounded,
        label: 'Команда',
        onTap: () => context.push('/projects/$projectId/team'),
      ),
      _NavTileSpec(
        icon: Icons.rule_rounded,
        label: 'Согласования',
        onTap: () => context.push('/projects/$projectId/approvals'),
      ),
      _NavTileSpec(
        icon: Icons.edit_note_outlined,
        label: 'Заметки',
        onTap: () => context.push('/projects/$projectId/notes'),
      ),
      _NavTileSpec(
        icon: Icons.menu_book_outlined,
        label: 'Методичка',
        onTap: () => context.push('/methodology'),
      ),
      _NavTileSpec(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Бюджет',
        onTap: () => context.push('/projects/$projectId/budget'),
      ),
      _NavTileSpec(
        icon: Icons.inventory_2_outlined,
        label: 'Материалы',
        onTap: () => context.push('/projects/$projectId/materials'),
      ),
      _NavTileSpec(
        icon: Icons.shopping_bag_outlined,
        label: 'Самозакуп',
        onTap: () => context.push('/projects/$projectId/selfpurchases'),
      ),
      _NavTileSpec(
        icon: Icons.construction_outlined,
        label: 'Инструмент',
        onTap: () => context.push('/projects/$projectId/tools'),
      ),
      _NavTileSpec(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Чаты',
        onTap: () => context.push('/projects/$projectId/chats'),
      ),
      _NavTileSpec(
        icon: Icons.insert_drive_file_outlined,
        label: 'Документы',
        onTap: () => context.push('/projects/$projectId/documents'),
      ),
      _NavTileSpec(
        icon: Icons.stream_outlined,
        label: 'Лента',
        onTap: () => context.push('/projects/$projectId/feed'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (_, i) {
        final t = tiles[i];
        return ConsoleNavTile(
          icon: t.icon,
          label: t.label,
          enabled: t.enabled,
          onTap: t.onTap,
        );
      },
    );
  }
}

class _NavTileSpec {
  _NavTileSpec({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  bool get enabled => onTap != null;
}
