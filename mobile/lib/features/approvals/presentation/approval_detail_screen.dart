import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/approvals_controller.dart';
import '../domain/approval.dart';
import 'approval_sheets.dart';
import 'approval_widgets.dart';

/// d-approval-detail / d-approval-extra / d-plan-approval / d-stage-accept /
/// d-deadline-change — унифицированный экран, варьирует тело по scope.
class ApprovalDetailScreen extends ConsumerWidget {
  const ApprovalDetailScreen({
    required this.projectId,
    required this.approvalId,
    super.key,
  });

  final String projectId;
  final String approvalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalDetailProvider(approvalId));

    return AppScaffold(
      showBack: true,
      title: 'Согласование',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(approvalDetailProvider(approvalId)),
        ),
        data: (approval) {
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(approvalDetailProvider(approvalId)),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x16,
                      AppSpacing.x12,
                      AppSpacing.x16,
                      AppSpacing.x24,
                    ),
                    children: [
                      Hero(
                        tag: 'approval-${approval.id}',
                        flightShuttleBuilder:
                            (_, __, dir, fromCtx, toCtx) {
                          final hero = (dir == HeroFlightDirection.push
                                  ? fromCtx
                                  : toCtx)
                              .widget as Hero;
                          return hero.child;
                        },
                        child: const SizedBox(height: 1),
                      ),
                      _Header(approval: approval),
                      if (approval.requiresReassign) ...[
                        const SizedBox(height: AppSpacing.x12),
                        _RequiresReassignBanner(approval: approval),
                      ],
                      const SizedBox(height: AppSpacing.x20),
                      _ScopeBody(approval: approval),
                      if (approval.decisionComment?.isNotEmpty ??
                          false) ...[
                        const SizedBox(height: AppSpacing.x16),
                        _DecisionBlock(approval: approval),
                      ],
                      if (approval.attempts.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x20),
                        const Text('История', style: AppTextStyles.h2),
                        const SizedBox(height: AppSpacing.x10),
                        ApprovalAttemptsList(attempts: approval.attempts),
                      ],
                    ],
                  ),
                ),
              ),
              _BottomActions(approval: approval),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(approval.scope);
    final df = DateFormat('d MMMM y', 'ru');
    final categoryRaw = approval.payload['category'];
    final category =
        categoryRaw is String && categoryRaw.trim().isNotEmpty
            ? categoryRaw
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ScopeBadge(label: approval.scope.displayName, tone: tone),
            if (category != null)
              ScopeBadge(label: category, tone: ScopeBadgeTone.category),
            AttemptBadge(attemptNumber: approval.attemptNumber),
            Text(
              df.format(approval.createdAt),
              style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x10),
        Text(
          _titleFor(approval),
          style: AppTextStyles.h1.copyWith(
            fontSize: 20,
            color: AppColors.n900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _subtitleFor(approval),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.n500,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

String _titleFor(Approval a) {
  final raw = a.payload['title'];
  if (raw is String && raw.trim().isNotEmpty) return raw;
  return switch (a.scope) {
    ApprovalScope.plan => 'Согласование плана работ',
    ApprovalScope.step => a.scope.displayName,
    ApprovalScope.extraWork => 'Дополнительная работа',
    ApprovalScope.deadlineChange => 'Перенос дедлайна',
    ApprovalScope.stageAccept => 'Приёмка этапа',
  };
}

String _subtitleFor(Approval a) {
  return switch (a.scope) {
    ApprovalScope.plan => 'Бригадир предложил план — проверьте этапы и сроки.',
    ApprovalScope.step =>
      'Подрядчик отправил шаг на согласование. Проверьте фото и комментарий.',
    ApprovalScope.extraWork =>
      'Бригадир запрашивает работу сверх плана. Подтвердите включение в бюджет.',
    ApprovalScope.deadlineChange =>
      'Бригадир просит сдвинуть дату завершения этапа.',
    ApprovalScope.stageAccept =>
      'Бригадир сдаёт этап на приёмку. Сверьте результат с задачей.',
  };
}

ScopeBadgeTone _toneFor(ApprovalScope scope) => switch (scope) {
      ApprovalScope.step => ScopeBadgeTone.step,
      ApprovalScope.extraWork => ScopeBadgeTone.extraWork,
      ApprovalScope.deadlineChange => ScopeBadgeTone.deadline,
      ApprovalScope.stageAccept => ScopeBadgeTone.stageAccept,
      ApprovalScope.plan => ScopeBadgeTone.plan,
    };

class _DecisionBlock extends StatelessWidget {
  const _DecisionBlock({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final isApproved = approval.status == ApprovalStatus.approved;
    final bg = isApproved ? AppColors.greenLight : AppColors.redBg;
    final fg = isApproved ? AppColors.greenDark : AppColors.redText;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isApproved ? 'Комментарий одобрившего' : 'Причина отказа',
            style: AppTextStyles.subtitle.copyWith(color: fg),
          ),
          const SizedBox(height: 6),
          Text(
            approval.decisionComment!,
            style: AppTextStyles.body.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// Тело экрана — зависит от scope.
class _ScopeBody extends StatelessWidget {
  const _ScopeBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    switch (approval.scope) {
      case ApprovalScope.plan:
        return _PlanBody(approval: approval);
      case ApprovalScope.step:
        return _StepBody(approval: approval);
      case ApprovalScope.extraWork:
        return _ExtraBody(approval: approval);
      case ApprovalScope.deadlineChange:
        return _DeadlineBody(approval: approval);
      case ApprovalScope.stageAccept:
        return _StageAcceptBody(approval: approval);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────
// Подобщие виджеты body
// ──────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.n400,
        letterSpacing: 0.5,
        height: 1.2,
      ),
    );
  }
}

class _CommentBox extends StatelessWidget {
  const _CommentBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n50,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.n700,
          height: 1.6,
        ),
      ),
    );
  }
}

class _DetailPhotoGrid extends StatelessWidget {
  const _DetailPhotoGrid({
    required this.attachments,
    required this.columns,
  });

  final List<ApprovalAttachment> attachments;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.n50,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.n200),
        ),
        child: Text(
          'Фото не приложено',
          style: AppTextStyles.caption.copyWith(color: AppColors.n400),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attachments.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final url = attachments[i].thumbUrl ?? attachments[i].url;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.n100,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          clipBehavior: Clip.antiAlias,
          child: url == null
              ? const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.n400,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.n400,
                  ),
                ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Step
// ──────────────────────────────────────────────────────────────────────

class _StepBody extends StatelessWidget {
  const _StepBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final comment = approval.payload['comment'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Фото'),
        const SizedBox(height: AppSpacing.x8),
        _DetailPhotoGrid(attachments: approval.attachments, columns: 3),
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Комментарий'),
          const SizedBox(height: AppSpacing.x8),
          _CommentBox(text: comment),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Extra Work
// ──────────────────────────────────────────────────────────────────────

class _ExtraBody extends StatelessWidget {
  const _ExtraBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final price = approval.extraPrice;
    final description = approval.extraDescription;
    final qty = approval.payload['quantity'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.x16),
          decoration: BoxDecoration(
            color: AppColors.purpleBg,
            borderRadius: AppRadius.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Стоимость',
                style: AppTextStyles.tiny.copyWith(color: AppColors.purple),
              ),
              const SizedBox(height: 4),
              Text(
                price == null ? '—' : Money.format(price),
                style: AppTextStyles.h1.copyWith(
                  fontSize: 26,
                  color: AppColors.purple,
                ),
              ),
              if (qty != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Количество: $qty',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Описание'),
          const SizedBox(height: AppSpacing.x8),
          _CommentBox(text: description),
        ],
        if (approval.attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Фото'),
          const SizedBox(height: AppSpacing.x8),
          _DetailPhotoGrid(attachments: approval.attachments, columns: 2),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Plan
// ──────────────────────────────────────────────────────────────────────

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final stages = approval.planStages;
    final totalDays = _totalDays(stages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.x16),
          decoration: BoxDecoration(
            gradient: AppGradients.planInfo,
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.shBlue,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.n0,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Бригадир предложил план',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.n0,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stages.isEmpty
                          ? 'Согласуется план в целом'
                          : '${stages.length} ${_plural(stages.length, 'этап', 'этапа', 'этапов')}'
                              '${totalDays != null ? ' · $totalDays дней' : ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.n0.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (stages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Предложенные этапы'),
          const SizedBox(height: AppSpacing.x8),
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.x8),
            _PlanStageRow(index: i + 1, data: stages[i]),
          ],
          const SizedBox(height: AppSpacing.x16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: AppRadius.card,
            ),
            child: Row(
              children: [
                Text(
                  'Итого',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.brand,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${stages.length} ${_plural(stages.length, "этап", "этапа", "этапов")}'
                  '${totalDays != null ? " · $totalDays дней" : ""}',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.brand,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  int? _totalDays(List<Map<String, dynamic>> stages) {
    var total = 0;
    var any = false;
    for (final s in stages) {
      final start = s['plannedStart'];
      final end = s['plannedEnd'];
      if (start is String && end is String) {
        final ds = DateTime.tryParse(start);
        final de = DateTime.tryParse(end);
        if (ds != null && de != null) {
          total += de.difference(ds).inDays;
          any = true;
        }
      }
    }
    return any ? total : null;
  }
}

class _PlanStageRow extends StatelessWidget {
  const _PlanStageRow({required this.index, required this.data});

  final int index;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Этап $index';
    final start = data['plannedStart']?.toString();
    final end = data['plannedEnd']?.toString();
    final df = DateFormat('d MMM', 'ru');
    final dateLine = [
      if (start != null) df.format(DateTime.parse(start)),
      if (end != null) df.format(DateTime.parse(end)),
    ].join(' — ');
    final stepCount = data['stepCount'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.n0,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.n700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 13,
                    color: AppColors.n800,
                  ),
                ),
                if (dateLine.isNotEmpty || stepCount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (stepCount != null) '$stepCount шагов',
                      if (dateLine.isNotEmpty) dateLine,
                    ].join(' · '),
                    style: AppTextStyles.tiny.copyWith(
                      fontSize: 11,
                      color: AppColors.n500,
                    ),
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

String _plural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

// ──────────────────────────────────────────────────────────────────────
// Deadline change
// ──────────────────────────────────────────────────────────────────────

class _DeadlineBody extends StatelessWidget {
  const _DeadlineBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final newEnd = approval.newEnd;
    final oldEndRaw = approval.payload['oldEnd'];
    final oldEnd =
        oldEndRaw is String ? DateTime.tryParse(oldEndRaw) : null;
    final reason = approval.payload['reason'] as String?;
    final df = DateFormat('d MMMM', 'ru');
    final delta = (oldEnd != null && newEnd != null)
        ? newEnd.difference(oldEnd).inDays
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateChip(
                label: 'Текущий',
                value: oldEnd == null ? '—' : df.format(oldEnd),
                tone: _DateTone.danger,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.x8),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.n400,
              ),
            ),
            Expanded(
              child: _DateChip(
                label: 'Новый',
                value: newEnd == null ? '—' : df.format(newEnd),
                tone: _DateTone.success,
              ),
            ),
          ],
        ),
        if (delta != null) ...[
          const SizedBox(height: AppSpacing.x12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.yellowBg,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.yellowText,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${delta >= 0 ? '+' : ''}$delta '
                  '${_plural(delta.abs(), "день", "дня", "дней")}',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.yellowText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (reason != null && reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Причина'),
          const SizedBox(height: AppSpacing.x8),
          _CommentBox(text: reason),
        ],
      ],
    );
  }
}

enum _DateTone { danger, success }

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final _DateTone tone;

  @override
  Widget build(BuildContext context) {
    final bg =
        tone == _DateTone.danger ? AppColors.redBg : AppColors.greenLight;
    final fg =
        tone == _DateTone.danger ? AppColors.redText : AppColors.greenDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.subtitle.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Stage accept
// ──────────────────────────────────────────────────────────────────────

class _StageAcceptBody extends StatelessWidget {
  const _StageAcceptBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final comment = approval.payload['comment'] as String?;
    final prevReject = _previousRejection(approval);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prevReject != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.redBg,
              borderRadius: AppRadius.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.redDot,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Прошлое отклонение',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.redText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prevReject,
                        style: AppTextStyles.body.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
        ],
        const _SectionLabel('Фото к приёмке'),
        const SizedBox(height: AppSpacing.x8),
        _DetailPhotoGrid(attachments: approval.attachments, columns: 2),
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Комментарий бригадира'),
          const SizedBox(height: AppSpacing.x8),
          _CommentBox(text: comment),
        ],
      ],
    );
  }

  String? _previousRejection(Approval a) {
    if (a.attemptNumber <= 1) return null;
    final rejected = a.attempts
        .where((x) => x.action == 'rejected' && (x.comment ?? '').isNotEmpty)
        .toList()
      ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    return rejected.isEmpty ? null : rejected.first.comment;
  }
}

// ──────────────────────────────────────────────────────────────────────
// Bottom actions
// ──────────────────────────────────────────────────────────────────────

class _BottomActions extends ConsumerWidget {
  const _BottomActions({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDecide = ref.watch(canInProjectProvider(
      (action: DomainAction.approvalDecide, projectId: approval.projectId),
    ));
    final canRequest = ref.watch(canInProjectProvider(
      (action: DomainAction.approvalRequest, projectId: approval.projectId),
    ));

    switch (approval.status) {
      case ApprovalStatus.pending:
        if (canDecide) {
          return AppActionBar(
            flexes: approval.scope == ApprovalScope.plan ? const [1, 2] : null,
            children: [
              AppButton(
                label: approval.scope == ApprovalScope.plan
                    ? 'Отклонить план'
                    : 'Отклонить',
                variant: AppButtonVariant.destructive,
                onPressed: () =>
                    showRejectSheet(context, ref, approval: approval),
              ),
              AppButton(
                label: approval.scope == ApprovalScope.plan
                    ? 'Принять план'
                    : 'Одобрить',
                variant: AppButtonVariant.success,
                onPressed: () =>
                    showApproveSheet(context, ref, approval: approval),
              ),
            ],
          );
        }
        if (canRequest) {
          return AppActionBar(
            children: [
              AppButton(
                label: 'Отменить заявку',
                variant: AppButtonVariant.ghost,
                onPressed: () => _cancel(context, ref),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      case ApprovalStatus.rejected:
        if (canRequest) {
          return AppActionBar(
            children: [
              AppButton(
                label: 'Отправить повторно',
                onPressed: () =>
                    showResubmitSheet(context, ref, approval: approval),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      case ApprovalStatus.approved:
      case ApprovalStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(approvalsControllerProvider(approval.projectId).notifier)
        .cancel(approval);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: failure == null ? 'Заявка отменена' : failure.userMessage,
      kind: failure == null ? AppToastKind.success : AppToastKind.error,
    );
  }
}

/// Баннер «Бригадир удалён со стадии» — требует переназначения, иначе
/// approval не сможет быть закрыт нормальным flow (gaps §3.3).
class _RequiresReassignBanner extends StatelessWidget {
  const _RequiresReassignBanner({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.redDot,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Бригадир удалён со стадии',
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.redText),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Согласование зависло — переназначьте бригадира в команде '
                  'проекта, чтобы можно было одобрить или отклонить.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.x10),
                AppButton(
                  label: 'Открыть команду',
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  onPressed: () => context.push(
                    AppRoutes.projectTeamWith(approval.projectId),
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
