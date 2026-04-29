import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/approvals_controller.dart';
import '../domain/approval.dart';

/// d-approved / d-rejected — полноэкранный результат после approve/reject.
///
/// Параметры берутся из роута:
/// - projectId, approvalId — для построения «Открыть детали»
/// - status — 'approved' | 'rejected'
class ApprovalResultScreen extends ConsumerWidget {
  const ApprovalResultScreen({
    required this.projectId,
    required this.approvalId,
    required this.status,
    super.key,
  });

  final String projectId;
  final String approvalId;

  /// 'approved' | 'rejected'.
  final String status;

  bool get _isError => status == 'rejected';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalDetailProvider(approvalId));

    return Stack(
      children: [
        SuccessScreen(
          title: _isError ? 'Согласование отклонено' : 'Этап одобрен',
          subtitle: async.maybeWhen(
            data: _summaryFor,
            orElse: () => null,
          ),
          isError: _isError,
          primaryLabel: 'К списку согласований',
          onPrimary: () => context.go('/projects/$projectId/approvals'),
          secondaryLabel: 'Открыть детали',
          onSecondary: () => context.push(
            AppRoutes.approvalDetailWith(approvalId)
                .replaceFirst('/approvals/', '/projects/$projectId/approvals/'),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.x16 +
              MediaQuery.of(context).padding.bottom +
              160,
          child: Center(
            child: async.maybeWhen(
              data: (a) => _ResultMetaCard(approval: a, isError: _isError),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  String? _summaryFor(Approval a) {
    final scope = a.scope.displayName;
    return _isError
        ? 'Бригада увидит ваш комментарий и сможет переотправить заявку.'
        : 'Согласование «$scope» закрыто. Изменения попали в проект.';
  }
}

class _ResultMetaCard extends StatelessWidget {
  const _ResultMetaCard({required this.approval, required this.isError});

  final Approval approval;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMMM y · HH:mm', 'ru');
    final decidedAt = approval.decidedAt ?? approval.updatedAt;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.x24),
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaRow(label: 'Категория', value: approval.scope.displayName),
          const SizedBox(height: 6),
          _MetaRow(label: 'Дата', value: df.format(decidedAt)),
          if (approval.attemptNumber > 1) ...[
            const SizedBox(height: 6),
            _MetaRow(
              label: 'Попытка',
              value: '№${approval.attemptNumber}',
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.n800,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
