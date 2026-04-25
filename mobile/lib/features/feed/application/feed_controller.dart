import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feed_repository.dart';
import '../domain/feed_event.dart';

/// Состояние ленты для одного проекта.
@immutable
class FeedState {
  const FeedState({
    this.items = const [],
    this.cursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filter,
  });

  final List<FeedEvent> items;
  final String? cursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  /// Активный фильтр-категория (null — все).
  final FeedCategory? filter;

  FeedState copyWith({
    List<FeedEvent>? items,
    String? cursor,
    bool clearCursor = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    FeedCategory? filter,
    bool clearFilter = false,
  }) =>
      FeedState(
        items: items ?? this.items,
        cursor: clearCursor ? null : (cursor ?? this.cursor),
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        filter: clearFilter ? null : (filter ?? this.filter),
      );

  /// Отфильтрованный список (по category) — applied после сортировки.
  List<FeedEvent> get visible =>
      filter == null ? items : items.where((e) => e.category == filter).toList();
}

/// Семейство контроллеров на projectId.
final feedControllerProvider = NotifierProvider.autoDispose
    .family<FeedController, FeedState, String>(FeedController.new);

/// Размер страницы, как и на бэке (бэк сам ограничивает <=100).
const _pageSize = 50;

class FeedController extends AutoDisposeFamilyNotifier<FeedState, String> {
  String get _projectId => arg;
  FeedRepository get _repo => ref.read(feedRepositoryProvider);

  @override
  FeedState build(String projectId) {
    // Запускаем первую загрузку асинхронно — build() не должен await'ить.
    Future.microtask(refresh);
    return const FeedState(isLoading: true);
  }

  /// Полное обновление: сброс cursor, items, перезагрузка первой страницы.
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCursor: true,
    );
    try {
      final page = await _repo.list(
        projectId: _projectId,
        limit: _pageSize,
      );
      state = FeedState(
        items: _sortByPriority(page.items),
        cursor: page.nextCursor,
        hasMore: page.nextCursor != null,
        filter: state.filter,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Подгрузка следующей страницы (вызывается из infinite-scroll trigger).
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!state.hasMore || state.cursor == null) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _repo.list(
        projectId: _projectId,
        cursor: state.cursor,
        limit: _pageSize,
      );
      state = state.copyWith(
        items: _sortByPriority([...state.items, ...page.items]),
        cursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  void setFilter(FeedCategory? category) {
    if (category == state.filter) return;
    state = state.copyWith(
      filter: category,
      clearFilter: category == null,
    );
  }

  /// Приоритет approval над stage_*: ТЗ §5.2 / §10. Сортировка стабильная,
  /// сначала по приоритету категории, затем по дате (DESC).
  List<FeedEvent> _sortByPriority(List<FeedEvent> input) {
    return [...input]
      ..sort((a, b) {
        final ap = _priority(a.category);
        final bp = _priority(b.category);
        if (ap != bp) return ap.compareTo(bp);
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  static int _priority(FeedCategory c) => switch (c) {
        FeedCategory.approval => 0,
        FeedCategory.finance => 1,
        FeedCategory.stage => 2,
        FeedCategory.step => 3,
        FeedCategory.materials => 4,
        FeedCategory.documents => 5,
        FeedCategory.chat => 6,
        FeedCategory.project => 7,
        FeedCategory.other => 8,
      };
}
