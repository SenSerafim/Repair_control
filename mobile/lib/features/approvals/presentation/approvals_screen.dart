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
  ApprovalScope? _scope;

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
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.n0,
            child: TabBar(
              controller: _tabs,
              labelStyle:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800),
              labelColor: AppColors.brand,
              unselectedLabelColor: AppColors.n400,
              indicatorColor: AppColors.brand,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Активные'),
                Tab(text: 'История'),
              ],
            ),
          ),
          _ScopeChips(
            selected: _scope,
            onSelected: (s) => setState(() => _scope = s),
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const AppLoadingState(skeleton: AppListSkeleton()),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить',
                onRetry: () => ref
                    .invalidate(approvalsControllerProvider(widget.projectId)),
              ),
              data: (buckets) => TabBarView(
                controller: _tabs,
                children: [
                  _ListBody(
                    projectId: widget.projectId,
                    items: _filter(buckets.pending),
                    emptyTitle: 'Нет активных согласований',
                    emptyHint:
                        'Здесь появятся заявки, которые ждут вашего решения.',
                  ),
                  _ListBody(
                    projectId: widget.projectId,
                    items: _filter(buckets.history),
                    emptyTitle: 'История пуста',
                    emptyHint:
                        'Решённые и отклонённые согласования сохранятся здесь.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Approval> _filter(List<Approval> src) {
    if (_scope == null) return src;
    return src.where((a) => a.scope == _scope).toList();
  }
}

class _ScopeChips extends StatelessWidget {
  const _ScopeChips({required this.selected, required this.onSelected});

  final ApprovalScope? selected;
  final ValueChanged<ApprovalScope?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        children: [
          _Chip(
            label: 'Все',
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final s in ApprovalScope.values) ...[
            const SizedBox(width: AppSpacing.x8),
            _Chip(
              label: s.displayName,
              active: selected == s,
              onTap: () => onSelected(s),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x6,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.n100,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.n0 : AppColors.n700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(AppSpacing.x16),
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
