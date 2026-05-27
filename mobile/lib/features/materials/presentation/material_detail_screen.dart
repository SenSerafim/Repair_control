import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/materials_controller.dart';
import '../domain/material_request.dart';
import '_widgets/material_meta_card.dart';

/// Простой и прозрачный поток (UI/UX-упрощение 2026-05):
///   - foreman/master создаёт → «Ждёт согласования». Заказчик решает.
///   - customer/representative.canApprove создаёт → сразу «Согласовано».
///   - Отклонено — остаётся в истории. Все роли видят это сразу.
class MaterialDetailScreen extends ConsumerWidget {
  const MaterialDetailScreen({
    required this.projectId,
    required this.requestId,
    super.key,
  });

  final String projectId;
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      materialsControllerProvider(projectId).select(
        (v) => v.whenData(
          (list) => list.cast<MaterialRequest?>().firstWhere(
            (r) => r?.id == requestId,
            orElse: () => null,
          ),
        ),
      ),
    );

    return AppScaffold(
      showBack: true,
      title: 'Заявка',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Ошибка',
          onRetry: () => ref.invalidate(materialsControllerProvider(projectId)),
        ),
        data: (request) {
          if (request == null) {
            return const AppEmptyState(
              title: 'Заявка не найдена',
              icon: Icons.error_outline,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(materialsControllerProvider(projectId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                _Header(request: request),
                const SizedBox(height: AppSpacing.x16),
                _StatusBanner(status: request.status),
                const SizedBox(height: AppSpacing.x16),
                const _SectionLabel(label: 'Позиции'),
                const SizedBox(height: AppSpacing.x10),
                for (final item in request.items) ...[
                  _ItemRow(item: item),
                  const SizedBox(height: AppSpacing.x8),
                ],
                if (request.comment?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.x16),
                  _CommentCard(comment: request.comment!),
                ],
                const SizedBox(height: AppSpacing.x16),
                const _SectionLabel(label: 'Детали'),
                const SizedBox(height: AppSpacing.x10),
                MaterialMetaCard(rows: _metaRows(request)),
                const SizedBox(height: AppSpacing.x20),
              ],
            ),
          );
        },
      ),
    );
  }

  List<MaterialMetaRow> _metaRows(MaterialRequest r) {
    return [
      MaterialMetaRow('Получатель покупает', r.recipient.displayName),
      MaterialMetaRow('Этап', r.stageId == null ? 'Без этапа' : 'Привязан'),
      MaterialMetaRow('Создал', _shorten(r.createdById)),
      MaterialMetaRow('Создано', _fmtDate(r.createdAt)),
      if (r.finalizedAt != null && r.status == MaterialRequestStatus.approved)
        MaterialMetaRow(
          'Согласовано',
          _fmtDate(r.finalizedAt!),
          valueColor: AppColors.greenDark,
        ),
    ];
  }

  String _fmtDate(DateTime d) => DateFormat('d MMM y · HH:mm', 'ru').format(d);

  String _shorten(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 12)}…';
}

class _Header extends StatelessWidget {
  const _Header({required this.request});

  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        gradient: AppGradients.surfaceCard,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
        border: Border.all(color: AppColors.n200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.title,
            style: AppTextStyles.h1.copyWith(fontSize: 20, letterSpacing: -0.5),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.x8),
          Row(
            children: [
              StatusPill(
                label: request.status.displayName,
                semaphore: request.status.semaphore,
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  '${request.items.length} позиций · '
                  '${Money.format(request.totalEstimatedPrice)}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final MaterialRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MaterialRequestStatus.pendingApproval => const _Banner(
        icon: Icons.hourglass_top_rounded,
        title: 'Ждёт согласования заказчиком',
        subtitle:
            'Решение появится у всех ролей сразу. Если заказчик отклонит — '
            'заявка останется в истории.',
        color: AppColors.n200,
        iconColor: AppColors.n600,
      ),
      MaterialRequestStatus.approved => const _Banner(
        icon: Icons.check_circle_outline_rounded,
        title: 'Согласовано',
        subtitle:
            'Сумма заявки списана из materials-бюджета проекта. Видна всем ролям.',
        color: AppColors.greenLight,
        iconColor: AppColors.greenDark,
      ),
      MaterialRequestStatus.rejected => const _Banner(
        icon: Icons.cancel_outlined,
        title: 'Заказчик отклонил заявку',
        subtitle:
            'Бюджет не списан. Заявка видна всем участникам проекта в истории.',
        color: Color(0xFFFFE5E0),
        iconColor: Color(0xFFB23A2A),
      ),
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n700,
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.n900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtQty(item.qty)} ${item.unit ?? ''}',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.n400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.totalPrice != null)
            Text(
              Money.format(item.totalPrice!),
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.n800,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.tiny.copyWith(
        color: AppColors.n400,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: AppRadius.card,
      ),
      child: Text(comment, style: AppTextStyles.body),
    );
  }
}
