import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../exports/presentation/export_sheet.dart';
import '../application/feed_controller.dart';
import '../domain/feed_event.dart';

/// f-feed / f-feed-empty / f-feed-filtered.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    // Триггерим loadMore когда осталось <300px до конца — даём UX-запас,
    // чтобы спиннер появлялся раньше чем пользователь упрётся в дно.
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 300) {
      ref.read(feedControllerProvider(widget.projectId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider(widget.projectId));
    final ctrl = ref.read(feedControllerProvider(widget.projectId).notifier);

    return AppScaffold(
      showBack: true,
      title: 'Лента',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          tooltip: 'Экспорт',
          icon: const Icon(Icons.cloud_download_outlined),
          onPressed: () =>
              showExportSheet(context, ref, projectId: widget.projectId),
        ),
      ],
      body: Column(
        children: [
          _CategoryFilter(
            selected: state.filter,
            onChanged: ctrl.setFilter,
          ),
          Expanded(
            child: _body(state, ctrl),
          ),
        ],
      ),
    );
  }

  Widget _body(FeedState state, FeedController ctrl) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingState(skeleton: AppListSkeleton());
    }
    if (state.error != null && state.items.isEmpty) {
      return AppErrorState(
        title: 'Не удалось загрузить',
        onRetry: ctrl.refresh,
      );
    }
    final filtered = state.visible;
    if (filtered.isEmpty) {
      return AppEmptyState(
        title: state.filter == null
            ? 'Лента пуста'
            : 'Нет событий в этой категории',
        icon: Icons.stream_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: ctrl.refresh,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.all(AppSpacing.x16),
        itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x8),
        itemBuilder: (_, i) {
          if (i == filtered.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.x12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _FeedRow(event: filtered[i]);
        },
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
