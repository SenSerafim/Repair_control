import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/approvals_controller.dart';
import '../domain/approval.dart';
import 'approval_widgets.dart';

/// d-approvals / d-approvals-empty / d-approvals-history.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String _scopeId = 'all';

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(approvalsControllerProvider(widget.projectId));

    return AppScaffold(
      showBack: true,
      title: 'Согласования',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () =>
              ref.invalidate(approvalsControllerProvider(widget.projectId)),
        ),
        data: (buckets) {
          final pendingCount = _filter(buckets.pending).length;
          return Column(
            children: [
              _Tabs(controller: _tabs, pendingCount: pendingCount),
              _ScopeFilter(
                activeId: _scopeId,
                onSelect: (id) => setState(() => _scopeId = id),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ListBody(
                      projectId: widget.projectId,
                      items: _filter(buckets.pending),
                      emptyTitle: 'Нет согласований',
                      emptyHint: 'Согласования появятся когда подрядчик '
                          'отправит шаг или этап на проверку.',
                    ),
                    _ListBody(
                      projectId: widget.projectId,
                      items: _filter(buckets.history),
                      emptyTitle: 'История пуста',
                      emptyHint: 'Решённые и отклонённые согласования '
                          'сохранятся здесь.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Approval> _filter(List<Approval> src) {
    if (_scopeId == 'all') return src;
    return src.where((a) => a.scope.apiValue == _scopeId).toList();
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller, required this.pendingCount});

  final TabController controller;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.n0,
      child: TabBar(
        controller: controller,
        labelStyle:
            AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800),
        labelColor: AppColors.brand,
        unselectedLabelColor: AppColors.n400,
        indicatorColor: AppColors.brand,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2.5,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Активные'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  _CountBadge(count: pendingCount),
                ],
              ],
            ),
          ),
          const Tab(text: 'История'),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.redText,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ScopeFilter extends StatelessWidget {
  const _ScopeFilter({required this.activeId, required this.onSelect});

  final String activeId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = <AppFilterChipSpec>[
      const AppFilterChipSpec(id: 'all', label: 'Все'),
      for (final s in ApprovalScope.values)
        AppFilterChipSpec(id: s.apiValue, label: s.displayName),
    ];
    return ColoredBox(
      color: AppColors.n0,
      child: AppFilterChips(
        chips: chips,
        activeId: activeId,
        onSelect: onSelect,
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.projectId,
    required this.items,
    required this.emptyTitle,
    required this.emptyHint,
  });

  final String projectId;
  final List<Approval> items;
  final String emptyTitle;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        subtitle: emptyHint,
        icon: Icons.verified_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x10,
        AppSpacing.x16,
        AppSpacing.x20,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x10),
      itemBuilder: (_, i) => ApprovalCard(
        approval: items[i],
        onTap: () => context.push(
          '/projects/$projectId/approvals/${items[i].id}',
        ),
      ),
    );
  }
}
