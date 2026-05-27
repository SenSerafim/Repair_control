import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../approvals/application/approvals_controller.dart';
import '../../../approvals/domain/approval.dart';
import '../../../approvals/presentation/approval_widgets.dart';

/// Таб «Согл.» в детали этапа.
///
/// Фильтр: все approvals, привязанные к этапу прямым `stageId`-матчем (step /
/// extra_work / deadline_change / stage_accept / stage_create / material_purchase),
/// плюс `plan`-scope, в payload которого этот этап упомянут (план блокирует
/// запуск этапа, поэтому пользователю важно его видеть отсюда). Не-стейджевые
/// scope (selfPurchase без stageId) игнорируются — они живут
/// в финансовой вкладке.
///
/// Состав:
///   1. SliverPersistentHeader со scope-чипами для фильтрации
///   2. Секция «Ожидают решения · N» — ApprovalCard, tap → /approvals/:id
///   3. Секция «История» — те же ApprovalCard со статус-бейджем
///   4. Pull-to-refresh
///
/// Раньше тут была кастомная yellow `ApprovalPendingCard` с inline approve/reject,
/// но (а) она не показывала фото/payload-контекст, нужный для информированного
/// решения, (б) дублировала логику ApprovalsScreen и UX расходился. Теперь
/// единственное действие — открыть detail-экран с полным контекстом.
class StageApprovalsTab extends ConsumerWidget {
  const StageApprovalsTab({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalsControllerProvider(projectId));
    return async.when(
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить согласования',
        onRetry: () => ref.invalidate(approvalsControllerProvider(projectId)),
      ),
      data: (buckets) {
        final pending = buckets.pending
            .where((a) => approvalBelongsToStage(a, stageId))
            .toList();
        final history = buckets.history
            .where((a) => approvalBelongsToStage(a, stageId))
            .toList();
        return _Body(
          projectId: projectId,
          stageId: stageId,
          pending: pending,
          history: history,
          onRefresh: () => ref
              .read(approvalsControllerProvider(projectId).notifier)
              .refresh(),
        );
      },
    );
  }
}

/// Возвращает `true`, если согласование относится к указанному этапу.
///
/// Stage-scoped scope'ы: совпадение по `stageId`. Особый случай — `plan`:
/// stageId у самой записи нет (план project-wide), но в `payload.stages`
/// перечислены этапы, к которым он применяется. Совпадение → показать.
///
/// Экспортируется наружу: stage_detail_screen использует её для подсчёта
/// бейджа на табе, чтобы число совпадало с фильтром карточек.
bool approvalBelongsToStage(Approval a, String stageId) {
  if (a.stageId == stageId) return true;
  if (a.scope == ApprovalScope.plan) {
    return a.planStages.any((s) => s['stageId'] == stageId);
  }
  return false;
}

class _Body extends StatefulWidget {
  const _Body({
    required this.projectId,
    required this.stageId,
    required this.pending,
    required this.history,
    required this.onRefresh,
  });

  final String projectId;
  final String stageId;
  final List<Approval> pending;
  final List<Approval> history;
  final Future<void> Function() onRefresh;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _scopeId = 'all';

  List<Approval> _applyScope(List<Approval> src) {
    if (_scopeId == 'all') return src;
    return src.where((a) => a.scope.apiValue == _scopeId).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Чипы строим только из тех scope'ов, что реально встречаются у этого
    // этапа — иначе пользователь будет тапать пустые фильтры. «Все» добавляем
    // всегда, чтобы был способ сбросить выбор.
    final scopesOnStage = <ApprovalScope>{
      for (final a in widget.pending) a.scope,
      for (final a in widget.history) a.scope,
    };
    final chips = <AppFilterChipSpec>[
      const AppFilterChipSpec(id: 'all', label: 'Все'),
      for (final s in ApprovalScope.values)
        if (scopesOnStage.contains(s))
          AppFilterChipSpec(id: s.apiValue, label: s.displayName),
    ];

    final pending = _applyScope(widget.pending);
    final history = _applyScope(widget.history);

    if (widget.pending.isEmpty && widget.history.isEmpty) {
      // Pull-to-refresh должен работать и на пустом экране (свежие согласования
      // могут прийти, пока пользователь стоит на табе). AlwaysScrollable +
      // SizedBox под высоту вкладки → жест ловится, контент остаётся по центру.
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: const AppEmptyState(
                title: 'Согласований по этому этапу нет',
                subtitle:
                    'Здесь появятся отправленные на согласование шаги, '
                    'доп.работы, перенос дедлайна и приёмка этапа.',
                icon: Icons.fact_check_outlined,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (chips.length > 1)
          ColoredBox(
            color: AppColors.n0,
            child: AppFilterChips(
              chips: chips,
              activeId: _scopeId,
              onSelect: (id) => setState(() => _scopeId = id),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x16,
                AppSpacing.x12,
                AppSpacing.x16,
                AppSpacing.x20,
              ),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(text: 'Ожидают решения · ${pending.length}'),
                  const SizedBox(height: AppSpacing.x8),
                  for (final a in pending) ...[
                    ApprovalCard(
                      approval: a,
                      onTap: () => context.push(
                        '/projects/${widget.projectId}/approvals/${a.id}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                  ],
                  const SizedBox(height: AppSpacing.x12),
                ],
                if (history.isNotEmpty) ...[
                  _SectionHeader(text: 'История · ${history.length}'),
                  const SizedBox(height: AppSpacing.x8),
                  for (final a in history) ...[
                    ApprovalCard(
                      approval: a,
                      onTap: () => context.push(
                        '/projects/${widget.projectId}/approvals/${a.id}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                  ],
                ],
                // Под скоуп-фильтр могут попасть нулевые секции (например,
                // выбран scope, который есть только в истории). Тогда показываем
                // тонкий inline-плейсхолдер, чтобы экран не выглядел пустым
                // после chip-клика.
                if (pending.isEmpty && history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.x24),
                    child: Text(
                      'По выбранному фильтру согласований нет.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.n500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.tiny.copyWith(
        color: AppColors.n400,
        letterSpacing: 0.6,
      ),
    );
  }
}
