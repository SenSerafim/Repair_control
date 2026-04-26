import 'package:flutter/material.dart';

import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../team/domain/representative_rights_l10n.dart';

/// s-rep-rights — информационный экран о правах представителя.
/// Реальные права настраиваются в консоли проекта (S10,
/// Membership.representativeRights JSONB).
class RepRightsScreen extends StatelessWidget {
  const RepRightsScreen({super.key});

  static final _groups = <String, List<DomainAction>>{
    'Проекты': [
      DomainAction.projectEdit,
      DomainAction.projectArchive,
      DomainAction.projectInviteMember,
    ],
    'Этапы и шаги': [
      DomainAction.stageManage,
      DomainAction.stageStart,
      DomainAction.stagePause,
      DomainAction.stepManage,
      DomainAction.stepAddSubstep,
    ],
    'Согласования': [
      DomainAction.approvalRequest,
      DomainAction.approvalDecide,
    ],
    'Финансы': [
      DomainAction.financeBudgetView,
      DomainAction.financePaymentCreate,
      DomainAction.financePaymentConfirm,
      DomainAction.financePaymentDispute,
    ],
    'Материалы и инструмент': [
      DomainAction.materialsManage,
      DomainAction.selfPurchaseCreate,
      DomainAction.toolsIssue,
    ],
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Права представителя',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.x16),
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: AppRadius.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.brand,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Text(
                    'Конкретные права представителя настраиваются в '
                    'каждом проекте отдельно (экран «Команда» в консоли '
                    'проекта). Здесь — справочный список доступных действий.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.brandDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x20),
          for (final entry in _groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.x4,
                bottom: AppSpacing.x8,
              ),
              child: Text(entry.key, style: AppTextStyles.micro),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(AppRadius.r20),
                boxShadow: AppShadows.sh1,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    _ActionRow(action: entry.value[i]),
                    if (i < entry.value.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.x16,
                        ),
                        child:
                            Divider(height: 1, color: AppColors.n100),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final DomainAction action;

  @override
  Widget build(BuildContext context) {
    final label = kRightsRu[action];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.brand,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label?.title ?? action.value,
                  style: AppTextStyles.body,
                ),
                if (label != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    label.description,
                    style:
                        AppTextStyles.micro.copyWith(color: AppColors.n400),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
