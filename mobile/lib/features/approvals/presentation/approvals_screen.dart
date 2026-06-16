import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/realtime/socket_service.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // initState вместо `late final` — поздняя инициализация падает при
  // dispose-before-build (бывает в /tour при быстром переключении экранов).
  TabController? _tabs;
  String _scopeId = 'all';
  // ТЗ NEWFIX §1.3: фильтр по этапам сверху. 'all' = все этапы,
  // _noStageKey = согласования без stageId (например, materialPurchase
  // общей заявки на проект).
  static const String _noStageKey = '__no_stage__';
  String _stageId = 'all';

  // Polling safety-net: пока экран открыт, каждые 30s тихо обновляем список
  // ТОЛЬКО если WS-соединение упало. Это страховка для случаев Doze mode,
  // переключения mobile data, отозванного notification permission и т.п.
  // При живом WS — 0 запросов (real-time через approval:changed).
  static const _pollInterval = Duration(seconds: 30);
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _tabs?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Из background — push мог не дойти, socket ещё переподключается.
      // Дёргаем refresh явно, чтобы пользователь сразу увидел актуальный список.
      _refresh();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      final socket = ref.read(socketServiceProvider);
      if (socket.isConnected) return;
      _refresh();
    });
  }

  Future<void> _refresh() {
    return ref
        .read(approvalsControllerProvider(widget.projectId).notifier)
        .refresh();
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
          final tabs = _tabs!;
          final stagesAsync = ref.watch(
            stagesControllerProvider(widget.projectId),
          );
          final stages = stagesAsync.value ?? const <Stage>[];
          final stageMap = {for (final s in stages) s.id: s};
          final pendingCount = _filter(buckets.pending).length;
          String? labelFor(Approval a) {
            final s = a.stageId == null ? null : stageMap[a.stageId];
            if (s == null) return null;
            return 'Этап ${s.orderIndex + 1} · ${s.title}';
          }

          return Column(
            children: [
              _Tabs(controller: tabs, pendingCount: pendingCount),
              _ScopeFilter(
                activeId: _scopeId,
                onSelect: (id) => setState(() => _scopeId = id),
              ),
              _StageFilter(
                activeId: _stageId,
                stages: stages,
                onSelect: (id) => setState(() => _stageId = id),
                noStageKey: _noStageKey,
              ),
              Expanded(
                child: TabBarView(
                  controller: tabs,
                  children: [
                    _ListBody(
                      projectId: widget.projectId,
                      items: _filter(buckets.pending),
                      stageLabelOf: labelFor,
                      emptyTitle: 'Нет согласований',
                      emptyHint:
                          'Согласования появятся когда бригадир '
                          'отправит шаг или этап на проверку.',
                      withTourAnchor: true,
                      onRefresh: _refresh,
                    ),
                    _ListBody(
                      projectId: widget.projectId,
                      items: _filter(buckets.history),
                      stageLabelOf: labelFor,
                      emptyTitle: 'История пуста',
                      emptyHint:
                          'Решённые и отклонённые согласования '
                          'сохранятся здесь.',
                      onRefresh: _refresh,
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
    return src.where((a) {
      if (_scopeId != 'all' && a.scope.apiValue != _scopeId) return false;
      if (_stageId == 'all') return true;
      if (_stageId == _noStageKey) return a.stageId == null;
      return a.stageId == _stageId;
    }).toList();
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
    required this.onRefresh,
    this.stageLabelOf,
    this.withTourAnchor = false,
  });

  final String projectId;
  final List<Approval> items;
  final String emptyTitle;
  final String emptyHint;
  final Future<void> Function() onRefresh;
  // ТЗ NEWFIX §1.3: подпись этапа в каждой строке для проектного списка.
  final String? Function(Approval)? stageLabelOf;
  // TabBarView держит обе вкладки одновременно — чтобы не получить
  // дубль GlobalKey, anchor подключаем только в активной вкладке (pending).
  final bool withTourAnchor;

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator работает и над AppEmptyState (через AlwaysScrollable),
    // и над списком: жест pull-to-refresh — стандартный для всех вкладок.
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
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x16,
          AppSpacing.x10,
          AppSpacing.x16,
          AppSpacing.x20,
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x10),
        itemBuilder: (_, i) {
          final card = ApprovalCard(
            approval: items[i],
            stageLabel: stageLabelOf?.call(items[i]),
            onTap: () =>
                context.push('/projects/$projectId/approvals/${items[i].id}'),
          );
          return (i == 0 && withTourAnchor)
              ? TourAnchor(id: 'approvals.first_approval', child: card)
              : card;
        },
      ),
    );
  }
}

/// ТЗ NEWFIX §1.3: горизонтальные чипсы фильтра по этапам:
/// `Все · Этап 1 · Этап 2 · … · Без этапа`. Скрываем «Без этапа», если
/// в проекте нет ни одного approval без stageId — иначе мусор в UI.
class _StageFilter extends StatelessWidget {
  const _StageFilter({
    required this.activeId,
    required this.stages,
    required this.onSelect,
    required this.noStageKey,
  });

  final String activeId;
  final List<Stage> stages;
  final ValueChanged<String> onSelect;
  final String noStageKey;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x6,
        AppSpacing.x16,
        AppSpacing.x4,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StageChip(
              label: 'Все этапы',
              selected: activeId == 'all',
              onTap: () => onSelect('all'),
            ),
            const SizedBox(width: AppSpacing.x6),
            for (final s in stages) ...[
              _StageChip(
                label: 'Этап ${s.orderIndex + 1}',
                selected: activeId == s.id,
                onTap: () => onSelect(s.id),
              ),
              const SizedBox(width: AppSpacing.x6),
            ],
            _StageChip(
              label: 'Без этапа',
              selected: activeId == noStageKey,
              onTap: () => onSelect(noStageKey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.tiny.copyWith(
            color: selected ? Colors.white : AppColors.n700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
