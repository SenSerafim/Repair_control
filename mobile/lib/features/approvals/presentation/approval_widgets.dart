import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../domain/approval.dart';

/// Карточка согласования для списка `d-approvals`.
///
/// Слева thumbnail 56×56 (первое attachment либо n100+scope-icon),
/// справа scope-badge + attempt-badge, заголовок 15/w800, meta 11/n400,
/// при наличии attachments — photo-row 32×32 + «+N». Снизу chevron.
/// `stageAccept`-карточка выделяется синей рамкой 1.5px.
class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    required this.approval,
    required this.onTap,
    super.key,
  });

  final Approval approval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = approval.scope == ApprovalScope.stageAccept;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: 'approval-${approval.id}',
        flightShuttleBuilder: (_, __, dir, fromCtx, toCtx) {
          final hero =
              (dir == HeroFlightDirection.push ? fromCtx : toCtx).widget
                  as Hero;
          return hero.child;
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: highlight ? AppColors.brand : AppColors.n200,
                width: highlight ? 1.5 : 1,
              ),
              boxShadow: AppShadows.sh1,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(approval: approval),
                const SizedBox(width: AppSpacing.x12),
                Expanded(child: _Body(approval: approval)),
                const SizedBox(width: AppSpacing.x6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.n300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final url = approval.attachments.isNotEmpty
        ? approval.attachments.first.thumbUrl ??
            approval.attachments.first.url
        : null;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _IconFallback(approval: approval),
            )
          : _IconFallback(approval: approval),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        approval.scope.icon,
        color: AppColors.n400,
        size: 22,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.approval});

  final Approval approval;

  String get _title {
    final raw = approval.payload['title'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return approval.scope.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(approval.scope);
    final df = DateFormat('d MMM HH:mm', 'ru');

    // ClipRect защищает от RenderFlex overflow assert: Hero
    // `flightShuttleBuilder` в момент анимации перехода на ApprovalDetail
    // даёт Body очень маленький transient height (~12px), и без clipping
    // Flutter роняет debug assert. Визуально — те же миллисекунды flight.
    return ClipRect(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ScopeBadge(label: approval.scope.displayName, tone: tone),
            AttemptBadge(attemptNumber: approval.attemptNumber),
            if (approval.status != ApprovalStatus.pending)
              ScopeBadge(
                label: approval.status.displayName,
                tone: _statusTone(approval.status),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _title,
          style: AppTextStyles.subtitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.n900,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          _meta(approval, df),
          style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (approval.attachments.length > 1) ...[
          const SizedBox(height: 8),
          _PhotoRow(attachments: approval.attachments),
        ],
      ],
      ),
    );
  }

  static String _meta(Approval a, DateFormat df) {
    final hint = _subtitleFor(a);
    final date = df.format(a.createdAt);
    return hint.isEmpty ? date : '$hint · $date';
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.attachments});

  final List<ApprovalAttachment> attachments;

  static const _max = 3;

  @override
  Widget build(BuildContext context) {
    final visible = attachments.take(_max).toList();
    final extra = attachments.length - visible.length;
    return Row(
      children: [
        for (final a in visible) ...[
          _PhotoThumb(url: a.thumbUrl ?? a.url),
          const SizedBox(width: 4),
        ],
        if (extra > 0)
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            child: Text(
              '+$extra',
              style: AppTextStyles.tiny.copyWith(color: AppColors.n600),
            ),
          ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? const Icon(
              Icons.image_outlined,
              size: 16,
              color: AppColors.n400,
            )
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 16,
                color: AppColors.n400,
              ),
            ),
    );
  }
}

ScopeBadgeTone _toneFor(ApprovalScope scope) => switch (scope) {
      ApprovalScope.step => ScopeBadgeTone.step,
      ApprovalScope.extraWork => ScopeBadgeTone.extraWork,
      ApprovalScope.deadlineChange => ScopeBadgeTone.deadline,
      ApprovalScope.stageAccept => ScopeBadgeTone.stageAccept,
      ApprovalScope.plan => ScopeBadgeTone.plan,
    };

ScopeBadgeTone _statusTone(ApprovalStatus s) => switch (s) {
      ApprovalStatus.approved => ScopeBadgeTone.success,
      ApprovalStatus.rejected => ScopeBadgeTone.danger,
      ApprovalStatus.cancelled => ScopeBadgeTone.category,
      ApprovalStatus.pending => ScopeBadgeTone.plan,
    };

String _subtitleFor(Approval a) {
  switch (a.scope) {
    case ApprovalScope.plan:
      final count = a.planStages.length;
      return count > 0 ? 'План из $count этапов' : 'Согласование плана';
    case ApprovalScope.step:
      return a.decisionComment?.isNotEmpty ?? false
          ? a.decisionComment!
          : '';
    case ApprovalScope.extraWork:
      final price = a.extraPrice;
      return price == null ? 'Доп.работа' : Money.format(price);
    case ApprovalScope.deadlineChange:
      final end = a.newEnd;
      return end == null
          ? 'Перенос дедлайна'
          : 'До ${DateFormat('d MMM y', 'ru').format(end)}';
    case ApprovalScope.stageAccept:
      final count = a.acceptPhotoCount ?? 0;
      return count > 0 ? '$count фото' : '';
  }
}

/// Таймлайн попыток — для ApprovalDetail.
///
/// Дизайн `d-approvals-history`: stacked-cards. Новейшая попытка сверху,
/// предыдущие — в стопке за ней с нарастающим offset (-4px x 2, -8px x 2...)
/// и спадающей opacity (1.0 → 0.85 → 0.70 → 0.55). Отображается до 4 попыток
/// одновременно, остальные — fade-out.
class ApprovalAttemptsList extends StatelessWidget {
  const ApprovalAttemptsList({
    required this.attempts,
    this.maxVisible = 4,
    super.key,
  });

  final List<ApprovalAttempt> attempts;
  final int maxVisible;

  static const double _cardHeight = 92;
  static const double _stepOffset = 4;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) return const SizedBox.shrink();
    final sorted = [...attempts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visible = sorted.take(maxVisible).toList();
    final stackHeight =
        _cardHeight + (visible.length - 1) * _stepOffset * 2 + AppSpacing.x6;
    return SizedBox(
      height: stackHeight,
      child: Stack(
        children: [
          for (var i = visible.length - 1; i >= 0; i--)
            Positioned(
              top: i * _stepOffset * 2,
              left: i * _stepOffset,
              right: i * _stepOffset,
              child: Opacity(
                opacity: 1 - (i * 0.15).clamp(0.0, 0.6),
                child: _AttemptRow(attempt: visible[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt});

  final ApprovalAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (attempt.action) {
      'created' => (
          Icons.hourglass_top_outlined,
          AppColors.brand,
          'Создан',
        ),
      'approved' => (
          Icons.check_rounded,
          AppColors.greenDark,
          'Одобрен',
        ),
      'rejected' => (
          Icons.close_rounded,
          AppColors.redDot,
          'Отклонён',
        ),
      'resubmitted' => (
          Icons.refresh_rounded,
          AppColors.brand,
          'Повторно отправлен',
        ),
      'cancelled' => (
          Icons.do_disturb_alt_outlined,
          AppColors.n400,
          'Отменён',
        ),
      _ => (Icons.history_rounded, AppColors.n500, attempt.action),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n50,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.n200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.subtitle.copyWith(color: color),
                    ),
                    const Spacer(),
                    Text(
                      'Попытка №${attempt.attemptNumber}',
                      style: AppTextStyles.tiny,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM y · HH:mm', 'ru')
                      .format(attempt.createdAt),
                  style: AppTextStyles.caption,
                ),
                if (attempt.comment != null &&
                    attempt.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(attempt.comment!, style: AppTextStyles.body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
