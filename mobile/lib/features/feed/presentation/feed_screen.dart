import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../exports/presentation/export_sheet.dart';
import '../../team/application/team_controller.dart';
import '../application/feed_controller.dart';
import '../data/feed_repository.dart';
import '../domain/feed_event.dart';

/// `f-feed` / `f-feed-empty` / `f-feed-filtered` из дизайна `Кластер F`.
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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(feedControllerProvider(widget.projectId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider(widget.projectId));
    final ctrl = ref.read(feedControllerProvider(widget.projectId).notifier);

    return AppScaffold(
      showBack: true,
      title: 'Лента событий',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          tooltip: 'PDF за период',
          icon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: () => _exportPeriodPdf(context),
        ),
        IconButton(
          tooltip: 'Экспорт',
          icon: const Icon(Icons.cloud_download_outlined),
          onPressed: () =>
              showExportSheet(context, ref, projectId: widget.projectId),
        ),
      ],
      body: Column(
        children: [
          _buildFilterBar(state.filter, ctrl.setFilter),
          Expanded(child: _body(state, ctrl)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    FeedCategory? selected,
    ValueChanged<FeedCategory?> onChanged,
  ) {
    final chips = <AppFilterPillSpec>[
      const AppFilterPillSpec(id: '__all__', label: 'Все'),
      for (final c in FeedCategory.values)
        AppFilterPillSpec(id: c.name, label: c.displayName),
    ];
    final active = selected?.name ?? '__all__';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n100)),
      ),
      child: AppFilterPillBar(
        chips: chips,
        activeId: active,
        onSelect: (id) {
          if (id == '__all__') {
            onChanged(null);
          } else {
            onChanged(FeedCategory.values.firstWhere((c) => c.name == id));
          }
        },
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
        title: state.filter == null ? 'Нет событий' : 'Нет событий в категории',
        subtitle: state.filter == null
            ? 'Лента наполняется автоматически при работе с проектом. '
                  'Все действия фиксируются здесь'
            : 'Попробуйте сменить фильтр',
        icon: Icons.stream_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: ctrl.refresh,
      child: ListView.separated(
        controller: _scroll,
        padding: EdgeInsets.zero,
        itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, thickness: 1, color: AppColors.n100),
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
          return _FeedRow(event: filtered[i], projectId: widget.projectId);
        },
      ),
    );
  }

  Future<void> _exportPeriodPdf(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      helpText: 'Период для PDF',
      cancelText: 'Отмена',
      confirmText: 'OK',
    );
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Готовим PDF за период…'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final bytes = await ref.read(feedRepositoryProvider).downloadPdf(
            projectId: widget.projectId,
            dateFrom: DateTime(
              picked.start.year, picked.start.month, picked.start.day,
            ),
            dateTo: DateTime(
              picked.end.year, picked.end.month, picked.end.day, 23, 59, 59,
            ),
          );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/feed-${widget.projectId}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Лента событий за период',
      );
    } on FeedException catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Не удалось: ${e.failure.name}')),
      );
    }
  }
}

class _FeedRow extends ConsumerWidget {
  const _FeedRow({required this.event, required this.projectId});

  final FeedEvent event;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageTitle = event.payload['stageTitle'] as String?;
    final reason = event.payload['reason'] as String?;
    final timeStr = DateFormat(
      'dd.MM.yyyy, HH:mm',
      'ru',
    ).format(event.createdAt);
    // Серафим 08.06.2026: имя инициатора события — резолвится из team.
    String? actorName;
    final team = ref.watch(teamControllerProvider(projectId)).valueOrNull;
    if (team != null && event.actorId.isNotEmpty) {
      for (final m in team.members) {
        if (m.userId == event.actorId) {
          final u = m.user;
          if (u != null && u.firstName.isNotEmpty) {
            actorName = u.lastName.isEmpty
                ? u.firstName
                : '${u.firstName} ${u.lastName[0]}.';
          }
          break;
        }
      }
    }
    final subtitleParts = <String>[
      timeStr,
      if (actorName != null) actorName,
      if (stageTitle != null && stageTitle.isNotEmpty) stageTitle,
    ];
    if (reason != null && reason.isNotEmpty) {
      subtitleParts.add('Причина: $reason');
    }
    return Container(
      color: AppColors.n0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xE6FFFFFF),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Color(0x260D1229),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AppFeedDot(tone: event.dotTone),
          ),
          const SizedBox(height: 8),
          Text(
            event.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.n800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitleParts.join(' — '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.n400,
              height: 1.4,
            ),
          ),
          if (event.isImmutable) ...[
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.n200, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080D1229),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: const AppImmutableBadge(),
            ),
          ],
        ],
      ),
    );
  }
}
