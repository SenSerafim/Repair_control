import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/feed_repository.dart';
import '../domain/feed_event.dart';

final _categoryFilterProvider =
    StateProvider.autoDispose<FeedCategory?>((_) => null);

final _feedProvider = FutureProvider.autoDispose
    .family<List<FeedEvent>, String>((ref, projectId) async {
  final page = await ref
      .read(feedRepositoryProvider)
      .list(projectId: projectId, limit: 100);
  return page.items;
});

/// f-feed / f-feed-empty / f-feed-filtered.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_feedProvider(projectId));
    final filter = ref.watch(_categoryFilterProvider);

    return AppScaffold(
      showBack: true,
      title: 'Лента',
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          _CategoryFilter(
            selected: filter,
            onChanged: (v) =>
                ref.read(_categoryFilterProvider.notifier).state = v,
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const AppLoadingState(skeleton: AppListSkeleton()),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить',
                onRetry: () => ref.invalidate(_feedProvider(projectId)),
              ),
              data: (events) {
                final filtered = filter == null
                    ? events
                    : events.where((e) => e.category == filter).toList();
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: filter == null
                        ? 'Лента пуста'
                        : 'Нет событий в этой категории',
                    icon: Icons.stream_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(_feedProvider(projectId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x8),
                    itemBuilder: (_, i) => _FeedRow(event: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});

  final FeedCategory? selected;
  final ValueChanged<FeedCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        children: [
          _chip('Все', null),
          for (final c in FeedCategory.values) ...[
            const SizedBox(width: AppSpacing.x8),
            _chip(c.displayName, c),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, FeedCategory? c) {
    final active = c == selected;
    return Builder(
      builder: (context) => Center(
        child: GestureDetector(
          onTap: () => onChanged(c),
          behavior: HitTestBehavior.opaque,
          child: Container(
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
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.event});
  final FeedEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            child: Icon(
              event.category.icon,
              color: AppColors.brand,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.summary, style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(
                  '${event.category.displayName} · '
                  '${DateFormat('d MMM y · HH:mm', 'ru').format(event.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
