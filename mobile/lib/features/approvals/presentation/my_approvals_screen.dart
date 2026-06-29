import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/my_approvals_controller.dart';
import '../data/approvals_repository.dart';
import 'approval_widgets.dart';

/// «Мои согласования» — глобальный экран по всем проектам.
/// Открывается из профиля по `/approvals`.
class MyApprovalsScreen extends ConsumerStatefulWidget {
  const MyApprovalsScreen({super.key});

  @override
  ConsumerState<MyApprovalsScreen> createState() => _MyApprovalsScreenState();
}

class _MyApprovalsScreenState extends ConsumerState<MyApprovalsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(myApprovalsControllerProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myApprovalsControllerProvider);
    return AppScaffold(
      showBack: true,
      title: 'Мои согласования',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(myApprovalsControllerProvider),
        ),
        data: (buckets) {
          final tabs = _tabs!;
          return Column(
            children: [
              _Tabs(controller: tabs, pendingCount: buckets.pending.length),
              Expanded(
                child: TabBarView(
                  controller: tabs,
                  children: [
                    _MyList(
                      items: buckets.pending,
                      onRefresh: _refresh,
                      emptyTitle: 'Нет активных согласований',
                      emptyHint:
                          'Сюда попадают запросы, ждущие вашего решения, '
                          'и ваши собственные отправленные на проверку.',
                    ),
                    _MyList(
                      items: buckets.history,
                      onRefresh: _refresh,
                      emptyTitle: 'История пуста',
                      emptyHint:
                          'Здесь будут согласования, по которым уже принято '
                          'решение.',
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
        labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800),
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

class _MyList extends StatelessWidget {
  const _MyList({
    required this.items,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptyHint,
  });

  final List<MyApprovalItem> items;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: AppEmptyState(
                title: emptyTitle,
                subtitle: emptyHint,
                icon: Icons.verified_outlined,
              ),
            ),
          ],
        ),
      );
    }
    // Группируем по проекту: над каждой группой — компактный заголовок,
    // чтобы пользователь видел, к какому проекту относится согласование.
    final byProject = <String, List<MyApprovalItem>>{};
    final titleByProject = <String, String>{};
    for (final m in items) {
      byProject.putIfAbsent(m.approval.projectId, () => []).add(m);
      titleByProject[m.approval.projectId] = m.projectTitle;
    }
    final groupedKeys = byProject.keys.toList()
      ..sort((a, b) {
        final aMax = byProject[a]!
            .map((m) => m.approval.createdAt)
            .reduce((x, y) => x.isAfter(y) ? x : y);
        final bMax = byProject[b]!
            .map((m) => m.approval.createdAt)
            .reduce((x, y) => x.isAfter(y) ? x : y);
        return bMax.compareTo(aMax);
      });

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x16,
          AppSpacing.x10,
          AppSpacing.x16,
          AppSpacing.x20,
        ),
        itemCount: _flatCount(groupedKeys, byProject),
        itemBuilder: (_, i) =>
            _buildAt(context, i, groupedKeys, byProject, titleByProject),
      ),
    );
  }

  int _flatCount(
    List<String> keys,
    Map<String, List<MyApprovalItem>> grouped,
  ) {
    var n = 0;
    for (final k in keys) {
      n += 1 + grouped[k]!.length;
    }
    return n;
  }

  Widget _buildAt(
    BuildContext context,
    int index,
    List<String> keys,
    Map<String, List<MyApprovalItem>> grouped,
    Map<String, String> titles,
  ) {
    var cursor = 0;
    for (final k in keys) {
      if (index == cursor) {
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.x14,
            bottom: AppSpacing.x8,
          ),
          child: Text(
            titles[k] ?? 'Проект',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.n400,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        );
      }
      cursor += 1;
      final list = grouped[k]!;
      if (index < cursor + list.length) {
        final item = list[index - cursor];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x10),
          child: ApprovalCard(
            approval: item.approval,
            onTap: () => context.push(
              '/projects/${item.approval.projectId}/approvals/${item.approval.id}',
            ),
          ),
        );
      }
      cursor += list.length;
    }
    return const SizedBox.shrink();
  }
}
