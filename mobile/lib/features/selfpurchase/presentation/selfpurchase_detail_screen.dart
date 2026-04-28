import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../finance/presentation/_widgets/payment_info_card.dart';
import '../../materials/presentation/_widgets/material_lifecycle_timeline.dart';
import '../application/selfpurchase_controller.dart';
import '../domain/self_purchase.dart';
import '_widgets/approval_chain_strip.dart';
import '_widgets/selfpurchase_amount_hero.dart';

/// e-selfpurchase-pending / -confirmed / -rejected / -foreman:
/// единый экран детали с переключаемым layout-ом (3-tier chain visualisation).
class SelfPurchaseDetailScreen extends ConsumerWidget {
  const SelfPurchaseDetailScreen({
    required this.projectId,
    required this.id,
    super.key,
  });

  final String projectId;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).userId;
    final async = ref.watch(
      selfpurchasesControllerProvider(projectId).select(
        (v) => v.whenData(
          (list) => list
              .cast<SelfPurchase?>()
              .firstWhere((s) => s?.id == id, orElse: () => null),
        ),
      ),
    );

    return AppScaffold(
      showBack: true,
      title: 'Самозакуп',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () =>
              ref.invalidate(selfpurchasesControllerProvider(projectId)),
        ),
        data: (sp) {
          if (sp == null) {
            return const AppEmptyState(
              title: 'Самозакуп не найден',
              icon: Icons.error_outline_rounded,
            );
          }
          return _Body(sp: sp, meId: me, projectId: projectId);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.sp,
    required this.meId,
    required this.projectId,
  });

  final SelfPurchase sp;
  final String? meId;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAddressee = sp.addresseeId == meId &&
        sp.status == SelfPurchaseStatus.pending;
    final viewerIsForeman = isAddressee && sp.byRole == SelfPurchaseBy.master;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x16),
            children: [
              Center(
                child: StatusPill(
                  label: sp.status.displayName,
                  semaphore: sp.status.semaphore,
                ),
              ),
              SelfPurchaseAmountHero(sp: sp),
              if (sp.status == SelfPurchaseStatus.approved)
                _ApprovedBanner(sp: sp),
              if (sp.status == SelfPurchaseStatus.rejected)
                _RejectedBanner(sp: sp),
              if (sp.status == SelfPurchaseStatus.pending)
                ApprovalChainStrip(
                  steps: _chainSteps(sp, viewerIsForeman: viewerIsForeman),
                  footnote: viewerIsForeman
                      ? 'После вашего подтверждения → автоматически уйдёт заказчику'
                      : 'Бригадир купил → отправил вам на подтверждение',
                ),
              const SizedBox(height: AppSpacing.x12),
              PaymentInfoCard(rows: _infoRows(sp)),
              if (sp.status == SelfPurchaseStatus.approved) ...[
                const SizedBox(height: AppSpacing.x16),
                MaterialLifecycleTimeline(steps: _lifecycleSteps(sp)),
              ],
              if (sp.decisionComment?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.x12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: AppColors.n100,
                    borderRadius: AppRadius.card,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.n500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sp.decisionComment!,
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x20),
            ],
          ),
        ),
        if (isAddressee)
          _Actions(
            projectId: projectId,
            sp: sp,
            viewerIsForeman: viewerIsForeman,
          ),
      ],
    );
  }

  List<PaymentInfoRow> _infoRows(SelfPurchase sp) {
    final fmt = DateFormat('d MMM y', 'ru');
    return [
      PaymentInfoRow('Сумма', Money.format(sp.amount)),
      PaymentInfoRow(
        'Этап',
        sp.stageId == null ? 'Без этапа' : 'Привязан',
      ),
      PaymentInfoRow('Купил', '${sp.byRole.displayName} (${_short(sp.byUserId)})'),
      PaymentInfoRow(
        'Дата покупки',
        '${fmt.format(sp.createdAt)} (неизменяемая)',
      ),
      if (sp.photoKeys.isNotEmpty)
        PaymentInfoRow(
          'Чеки',
          '${sp.photoKeys.length} фото',
          valueColor: AppColors.brand,
        ),
    ];
  }

  List<ChainStep> _chainSteps(SelfPurchase sp, {required bool viewerIsForeman}) {
    if (sp.byRole == SelfPurchaseBy.master) {
      return [
        ChainStep(
          label: '${_short(sp.byUserId)} (мастер)',
          state: ChainStepState.done,
          tone: ChainStepTone.purple,
        ),
        ChainStep(
          label: viewerIsForeman ? 'Вы (бригадир)' : 'Бригадир',
          state: viewerIsForeman ? ChainStepState.current : ChainStepState.done,
          tone: ChainStepTone.purple,
        ),
        const ChainStep(
          label: 'Заказчик',
          state: ChainStepState.pending,
          tone: ChainStepTone.customer,
        ),
      ];
    }
    return [
      ChainStep(
        label: '${_short(sp.byUserId)} (бригадир)',
        state: ChainStepState.done,
        tone: ChainStepTone.purple,
      ),
      const ChainStep(
        label: 'Вы (заказчик)',
        state: ChainStepState.current,
        tone: ChainStepTone.brand,
      ),
    ];
  }

  List<LifecycleStep> _lifecycleSteps(SelfPurchase sp) {
    return [
      LifecycleStep(
        title: 'Куплено',
        state: LifecycleStepState.done,
        dateLabel: DateFormat('d MMM y', 'ru').format(sp.createdAt),
        immutable: true,
      ),
      const LifecycleStep(
        title: 'Отправлено получателю',
        state: LifecycleStepState.done,
      ),
      LifecycleStep(
        title: 'Подтверждено',
        state: LifecycleStepState.done,
        dateLabel: sp.decidedAt == null
            ? null
            : DateFormat('d MMM y', 'ru').format(sp.decidedAt!),
      ),
      LifecycleStep(
        title: 'Добавлено в бюджет',
        state: LifecycleStepState.done,
        dateLabel: sp.decidedAt == null
            ? null
            : DateFormat('d MMM y', 'ru').format(sp.decidedAt!),
        immutable: true,
      ),
    ];
  }

  String _short(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 12)}…';
}

class _ApprovedBanner extends StatelessWidget {
  const _ApprovedBanner({required this.sp});

  final SelfPurchase sp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x12),
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        border: Border.all(color: const Color(0xFFA7F3D0)),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: AppColors.greenDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Самозакуп подтверждён!',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.greenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Money.format(sp.amount)} добавлены в бюджет (материалы)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner({required this.sp});

  final SelfPurchase sp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x12),
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close_rounded, color: AppColors.redDot, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Самозакуп отклонён',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.redText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sp.decisionComment ?? 'Причина не указана',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.redText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.projectId,
    required this.sp,
    required this.viewerIsForeman,
  });

  final String projectId;
  final SelfPurchase sp;
  final bool viewerIsForeman;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Отклонить',
                variant: AppButtonVariant.destructive,
                onPressed: () => context.push(
                  '/projects/$projectId/selfpurchases/${sp.id}/reject',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              flex: 2,
              child: AppButton(
                label: viewerIsForeman ? 'Подтвердить → заказчику' : 'Подтвердить',
                variant: AppButtonVariant.success,
                icon: Icons.check_rounded,
                onPressed: () async {
                  final failure = await ref
                      .read(
                        selfpurchasesControllerProvider(projectId).notifier,
                      )
                      .approve(
                        id: sp.id,
                        forwardOnApprove: viewerIsForeman,
                      );
                  if (!context.mounted) return;
                  if (failure != null) {
                    AppToast.show(
                      context,
                      message: failure.userMessage,
                      kind: AppToastKind.error,
                    );
                    return;
                  }
                  AppToast.show(
                    context,
                    message: viewerIsForeman
                        ? 'Передано заказчику'
                        : 'Подтверждено',
                    kind: AppToastKind.success,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
