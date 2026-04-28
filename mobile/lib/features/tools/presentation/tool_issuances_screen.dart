import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/error/api_error.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../team/application/team_controller.dart';
import '../application/tools_controller.dart';
import '../data/tools_repository.dart';
import '../domain/tool.dart';
import '_widgets/tool_filter_bar.dart';
import '_widgets/tool_row.dart';
import '_widgets/tool_search_bar.dart';
import '_widgets/tool_status_tabs.dart';
import '_widgets/tool_surrender_sheet.dart';

/// In-memory set юзеров, кому только что выдали инструмент. Сбрасывается
/// при перезагрузке экрана. Используется для green-dot indicator.
final _recentlyAddedHoldersProvider =
    StateProvider.autoDispose<Set<String>>((ref) => <String>{});

/// e-instruments: search + filter-chips per person + status-tabs + alphabetical
/// list. IconButton «+» в header → IssueToolScreen.
class ToolIssuancesScreen extends ConsumerStatefulWidget {
  const ToolIssuancesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<ToolIssuancesScreen> createState() =>
      _ToolIssuancesScreenState();
}

class _ToolIssuancesScreenState extends ConsumerState<ToolIssuancesScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _personFilter;
  ToolStatusTab _tab = ToolStatusTab.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canIssue = ref.watch(canProvider(DomainAction.toolsIssue));
    final issuancesAsync =
        ref.watch(toolIssuancesProvider(widget.projectId));
    final teamAsync = ref.watch(teamControllerProvider(widget.projectId));
    final me = ref.watch(authControllerProvider).userId;
    final recentlyAdded = ref.watch(_recentlyAddedHoldersProvider);

    return AppScaffold(
      showBack: true,
      title: 'Инструмент',
      padding: EdgeInsets.zero,
      actions: [
        if (canIssue)
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _openIssueScreen(context),
          ),
      ],
      body: issuancesAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) {
          if (e is ToolsException &&
              e.apiError.kind == ApiErrorKind.forbidden) {
            return const AppEmptyState(
              title: 'Раздел недоступен',
              subtitle: 'У вашей роли нет доступа к инструменту проекта.',
              icon: Icons.lock_outline_rounded,
            );
          }
          return AppErrorState(
            title: 'Не удалось загрузить',
            onRetry: () =>
                ref.invalidate(toolIssuancesProvider(widget.projectId)),
          );
        },
        data: (issuances) {
          final visible = _filtered(issuances);
          final allCount = issuances.length;
          final issuedCount = issuances
              .where((i) => i.status != ToolIssuanceStatus.returned)
              .length;
          final warehouseCount = allCount - issuedCount;

          // Список пользователей для фильтр-бара (уникальные toUserId).
          final userIds = <String, String>{};
          final members = teamAsync.value?.members ?? const [];
          for (final iss in issuances) {
            final m = members
                .where((mb) => mb.userId == iss.toUserId)
                .firstOrNull;
            var label = 'Мастер';
            final user = m?.user;
            if (user != null) {
              label = '${user.firstName} ${user.lastName}'.trim();
            }
            userIds[iss.toUserId] = label.isEmpty ? 'Мастер' : label;
          }
          final persons = <({String? id, String label})>[
            (id: null, label: 'Все'),
            for (final entry in userIds.entries)
              (id: entry.key, label: entry.value),
          ];

          return Column(
            children: [
              // Mastersurrender-кнопка (если у viewer есть подтверждённые
              // выдачи): chip-style возле header.
              if (_hasMastersSurrender(issuances, me))
                _SurrenderHint(
                  onTap: () => showToolSurrenderSheet(
                    context,
                    ref,
                    projectId: widget.projectId,
                    issuances: issuances
                        .where((i) =>
                            i.status == ToolIssuanceStatus.confirmed &&
                            i.toUserId == me)
                        .toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x16,
                  AppSpacing.x10,
                  AppSpacing.x16,
                  0,
                ),
                child: ToolSearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              ToolFilterBar(
                persons: persons,
                selected: _personFilter,
                onChanged: (id) => setState(() => _personFilter = id),
                recentlyAddedIds: recentlyAdded,
              ),
              ToolStatusTabs(
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
                allCount: allCount,
                issuedCount: issuedCount,
                warehouseCount: warehouseCount,
              ),
              Expanded(
                child: visible.isEmpty
                    ? const AppEmptyState(
                        title: 'Ничего не найдено',
                        icon: Icons.search_off_rounded,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(
                          toolIssuancesProvider(widget.projectId),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.x16),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.x8),
                          itemBuilder: (_, i) {
                            final iss = visible[i];
                            final recipient = userIds[iss.toUserId] ?? 'Мастер';
                            return ToolRow.fromIssuance(
                              issuance: iss,
                              recipientName: recipient,
                              onTap: () => _handleAction(iss, me),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<ToolIssuance> _filtered(List<ToolIssuance> all) {
    var list = all;
    if (_personFilter != null) {
      list = list.where((i) => i.toUserId == _personFilter).toList();
    }
    if (_tab == ToolStatusTab.issued) {
      list = list
          .where((i) => i.status != ToolIssuanceStatus.returned)
          .toList();
    } else if (_tab == ToolStatusTab.warehouse) {
      list = list
          .where((i) => i.status == ToolIssuanceStatus.returned)
          .toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((i) =>
              (i.tool?.name ?? '').toLowerCase().contains(q))
          .toList();
    }
    return [...list]
      ..sort((a, b) =>
          (a.tool?.name ?? '').compareTo(b.tool?.name ?? ''));
  }

  bool _hasMastersSurrender(List<ToolIssuance> issuances, String? meId) {
    if (meId == null) return false;
    return issuances.any(
      (i) =>
          i.status == ToolIssuanceStatus.confirmed && i.toUserId == meId,
    );
  }

  Future<void> _openIssueScreen(BuildContext context) async {
    final newRecipient = await context
        .push<String?>('/projects/${widget.projectId}/tools/new');
    if (!mounted) return;
    if (newRecipient is String) {
      ref
          .read(_recentlyAddedHoldersProvider.notifier)
          .update((s) => {...s, newRecipient});
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: 'Инструмент выдан · ожидает подтверждения',
        kind: AppToastKind.success,
      );
    }
  }

  Future<void> _handleAction(ToolIssuance iss, String? meId) async {
    final ctrl = ref.read(toolIssuancesProvider(widget.projectId).notifier);
    if (iss.status == ToolIssuanceStatus.issued && iss.toUserId == meId) {
      await ctrl.confirm(iss.id);
      return;
    }
    if (iss.status == ToolIssuanceStatus.confirmed && iss.toUserId == meId) {
      // Сдача через surrender-sheet (мульти).
      return;
    }
    if (iss.status == ToolIssuanceStatus.returnRequested &&
        iss.issuedById == meId) {
      await ctrl.returnConfirm(iss.id);
    }
  }
}

class _SurrenderHint extends StatelessWidget {
  const _SurrenderHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x10,
        AppSpacing.x16,
        0,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.assignment_return_outlined,
                size: 18,
                color: AppColors.brand,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Сдать инструмент бригадиру',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.brandDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
