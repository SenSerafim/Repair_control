import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
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
                        // Симметричный шаттл со списком (approval_widgets.dart).
                        // SingleChildScrollView позволяет содержимому
                        // отрисоваться в естественную высоту, пока rect Hero
                        // анимируется от карточки списка к SizedBox(h:1).
                        flightShuttleBuilder: (_, __, dir, fromCtx, toCtx) {
                          final hero =
                              (dir == HeroFlightDirection.push
                                          ? fromCtx
                                          : toCtx)
                                      .widget
                                  as Hero;
                          return Material(
                            type: MaterialType.transparency,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: hero.child,
                            ),
                          );
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
                      if (approval.decisionComment?.isNotEmpty ?? false) ...[
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
    final category = categoryRaw is String && categoryRaw.trim().isNotEmpty
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
          style: AppTextStyles.h1.copyWith(fontSize: 20, color: AppColors.n900),
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
    ApprovalScope.stageCreate => 'Этап от бригадира',
    ApprovalScope.materialPurchase => 'Закупка материалов',
    ApprovalScope.selfPurchase => 'Самокуп мастера',
    ApprovalScope.defect => 'Шаг на доработку',
  };
}

String _subtitleFor(Approval a) {
  return switch (a.scope) {
    ApprovalScope.plan => 'Бригадир предложил план — проверьте этапы и сроки.',
    ApprovalScope.step =>
      'Бригадир отправил шаг на согласование. Проверьте фото и комментарий.',
    ApprovalScope.extraWork =>
      'Бригадир запрашивает работу сверх плана. Подтвердите включение в бюджет.',
    ApprovalScope.deadlineChange =>
      'Бригадир просит сдвинуть дату завершения этапа.',
    ApprovalScope.stageAccept =>
      'Бригадир сдаёт этап на приёмку. Сверьте результат с задачей.',
    ApprovalScope.stageCreate =>
      'Бригадир добавил новый этап. До согласования шаги заблокированы.',
    ApprovalScope.materialPurchase =>
      'Бригадир запрашивает закупку. После approve сумма спишется из бюджета.',
    ApprovalScope.selfPurchase =>
      'Мастер просит возместить расходы на материалы.',
    ApprovalScope.defect =>
      'Заказчик отправил шаг на доработку. Проверьте фото и описание.',
  };
}

ScopeBadgeTone _toneFor(ApprovalScope scope) => switch (scope) {
  ApprovalScope.step => ScopeBadgeTone.step,
  ApprovalScope.extraWork => ScopeBadgeTone.extraWork,
  ApprovalScope.deadlineChange => ScopeBadgeTone.deadline,
  ApprovalScope.stageAccept => ScopeBadgeTone.stageAccept,
  ApprovalScope.plan => ScopeBadgeTone.plan,
  // Новые scope (П2.2): группируем под близкие тона.
  ApprovalScope.stageCreate => ScopeBadgeTone.stageAccept,
  ApprovalScope.materialPurchase => ScopeBadgeTone.extraWork,
  ApprovalScope.selfPurchase => ScopeBadgeTone.extraWork,
  ApprovalScope.defect => ScopeBadgeTone.deadline,
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
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.card),
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
      case ApprovalScope.stageCreate:
        return _StageCreateBody(approval: approval);
      case ApprovalScope.materialPurchase:
        return _MaterialPurchaseBody(approval: approval);
      case ApprovalScope.selfPurchase:
        return _SelfPurchaseBody(approval: approval);
      case ApprovalScope.defect:
        return _DefectBody(approval: approval);
    }
  }
}

class _DefectBody extends StatelessWidget {
  const _DefectBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final description = approval.payload['description'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Что доработать'),
        const SizedBox(height: AppSpacing.x8),
        _CommentBox(
          text: description != null && description.isNotEmpty
              ? description
              : '—',
        ),
        const SizedBox(height: AppSpacing.x16),
        const _SectionLabel('Фото-доказательства'),
        const SizedBox(height: AppSpacing.x8),
        _DetailPhotoGrid(attachments: approval.attachments, columns: 3),
      ],
    );
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
  const _DetailPhotoGrid({required this.attachments, required this.columns});

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
            gradient: url == null ? AppGradients.photoPlaceholder : null,
            color: url == null ? null : AppColors.n100,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            boxShadow: AppShadows.sh1,
          ),
          clipBehavior: Clip.antiAlias,
          child: url == null
              ? const Center(
                  child: Icon(Icons.image_outlined, color: AppColors.brand),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: AppGradients.planInfoRich,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D4F6EF7),
                  offset: Offset(0, 12),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: IgnorePointer(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x2EFFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.n0,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Бригадир предложил план',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.n0,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stages.isEmpty
                                ? 'Согласуется план в целом'
                                : '${stages.length} ${_plural(stages.length, 'этап', 'этапа', 'этапов')}'
                                      '${totalDays != null ? ' · $totalDays дней' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xC7FFFFFF),
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    final oldEnd = oldEndRaw is String ? DateTime.tryParse(oldEndRaw) : null;
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
              child: Icon(Icons.arrow_forward_rounded, color: AppColors.n400),
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
    final bg = tone == _DateTone.danger
        ? AppColors.redBg
        : AppColors.greenLight;
    final fg = tone == _DateTone.danger
        ? AppColors.redText
        : AppColors.greenDark;
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
            style: AppTextStyles.tiny.copyWith(color: fg, letterSpacing: 0.4),
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
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.redDot.withValues(alpha: 0.18),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.redDot,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Прошлое отклонение',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.redText,
                          letterSpacing: -0.2,
                        ),
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
    final rejected =
        a.attempts
            .where(
              (x) => x.action == 'rejected' && (x.comment ?? '').isNotEmpty,
            )
            .toList()
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    return rejected.isEmpty ? null : rejected.first.comment;
  }
}

// ──────────────────────────────────────────────────────────────────────
// Stage create (П2.2 / 4.4) — этап от бригадира
// ──────────────────────────────────────────────────────────────────────

class _StageCreateBody extends StatelessWidget {
  const _StageCreateBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM y', 'ru');
    final title = approval.payload['title']?.toString();
    final start = _date(approval.payload['plannedStart']);
    final end = _date(approval.payload['plannedEnd']);
    final workBudget = (approval.payload['workBudget'] as num?)?.toInt();
    final materialsBudget = (approval.payload['materialsBudget'] as num?)
        ?.toInt();
    final comment = approval.payload['comment'] as String?;
    final days = (start != null && end != null)
        ? end.difference(start).inDays
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.x16),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: AppRadius.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  style: AppTextStyles.h2.copyWith(color: AppColors.brand),
                ),
                const SizedBox(height: AppSpacing.x10),
              ],
              if (start != null || end != null)
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      [
                        if (start != null) df.format(start),
                        if (end != null) df.format(end),
                      ].join(' — '),
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                    if (days != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· $days ${_plural(days, "день", "дня", "дней")}',
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        if (workBudget != null || materialsBudget != null) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Бюджет этапа'),
          const SizedBox(height: AppSpacing.x8),
          Row(
            children: [
              if (workBudget != null)
                Expanded(
                  child: _BudgetChip(label: 'Работа', amount: workBudget),
                ),
              if (workBudget != null && materialsBudget != null)
                const SizedBox(width: AppSpacing.x10),
              if (materialsBudget != null)
                Expanded(
                  child: _BudgetChip(
                    label: 'Материалы',
                    amount: materialsBudget,
                  ),
                ),
            ],
          ),
        ],
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

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

class _BudgetChip extends StatelessWidget {
  const _BudgetChip({required this.label, required this.amount});
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n50,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: 2),
          Text(
            Money.format(amount),
            style: AppTextStyles.subtitle.copyWith(color: AppColors.n800),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Material purchase (П2.2 / 6.1) — закупка материалов бригадиром
// ──────────────────────────────────────────────────────────────────────

class _MaterialPurchaseBody extends StatelessWidget {
  const _MaterialPurchaseBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final amount = (approval.payload['amount'] as num?)?.toInt();
    final supplier = approval.payload['supplier'] as String?;
    final comment = approval.payload['comment'] as String?;
    final items = (approval.payload['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

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
                'Сумма закупки',
                style: AppTextStyles.tiny.copyWith(color: AppColors.purple),
              ),
              const SizedBox(height: 4),
              Text(
                amount == null ? '—' : Money.format(amount),
                style: AppTextStyles.h1.copyWith(
                  fontSize: 26,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Спишется из бюджета материалов после approve',
                style: AppTextStyles.tiny.copyWith(color: AppColors.purple),
              ),
            ],
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Список'),
          const SizedBox(height: AppSpacing.x8),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      it['name']?.toString() ?? '—',
                      style: AppTextStyles.body,
                    ),
                  ),
                  if (it['qty'] != null)
                    Text(
                      '${it['qty']} ${it['unit'] ?? ''}'.trim(),
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.n500,
                      ),
                    ),
                ],
              ),
            ),
        ],
        if (supplier != null && supplier.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Поставщик'),
          const SizedBox(height: AppSpacing.x8),
          Text(supplier, style: AppTextStyles.body),
        ],
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Комментарий'),
          const SizedBox(height: AppSpacing.x8),
          _CommentBox(text: comment),
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
// Self purchase (П2.2 / 6.1) — самокуп мастера
// ──────────────────────────────────────────────────────────────────────

class _SelfPurchaseBody extends StatelessWidget {
  const _SelfPurchaseBody({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final amount = (approval.payload['amount'] as num?)?.toInt();
    final byRole = approval.payload['byRole'] as String?;
    final comment = approval.payload['comment'] as String?;
    final kind = approval.payload['kind'] as String? ?? 'materials';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'К возмещению',
                style: AppTextStyles.tiny.copyWith(color: AppColors.n0),
              ),
              const SizedBox(height: 4),
              Text(
                amount == null ? '—' : Money.format(amount),
                style: AppTextStyles.h1.copyWith(
                  fontSize: 26,
                  color: AppColors.n0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kind == 'work'
                    ? 'Спишется из бюджета работ после approve'
                    : 'Спишется из бюджета материалов после approve',
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.n0.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        if (byRole != null) ...[
          const SizedBox(height: AppSpacing.x12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.n50,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.n500,
                ),
                const SizedBox(width: 6),
                Text(
                  byRole == 'master'
                      ? 'Заявка от мастера'
                      : 'Заявка от бригадира',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.n700),
                ),
              ],
            ),
          ),
        ],
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Комментарий'),
          const SizedBox(height: AppSpacing.x8),
          _CommentBox(text: comment),
        ],
        if (approval.attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          const _SectionLabel('Чеки и фото'),
          const SizedBox(height: AppSpacing.x8),
          _DetailPhotoGrid(attachments: approval.attachments, columns: 2),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Bottom actions
// ──────────────────────────────────────────────────────────────────────

class _BottomActions extends ConsumerWidget {
  const _BottomActions({required this.approval});

  final Approval approval;

  /// П2.6 / П7.7 — CTA «Принять/Отклонить» показываются ТОЛЬКО тому, чья
  /// активная роль совпадает с `Approval.actorRole` текущей ступени.
  /// Если actorRole не задан (старые approvals без двухступенчатой FSM) —
  /// fallback на проверку `addresseeId == me`: открытый «всем кто может»
  /// раньше давал бригадиру кнопку «Одобрить» на плане заказчика → 403.
  bool _matchesActorRole(WidgetRef ref) {
    final activeRole = ref.read(activeRoleProvider);
    final actorRole = approval.actorRole;
    if (actorRole == null) {
      final me = ref.read(authControllerProvider).userId;
      // addresseeId — тот, кому адресован approval. Совпадает с me →
      // активный пользователь и есть decision-maker, иначе CTA прячем.
      return me != null && approval.addresseeId == me;
    }
    switch (actorRole) {
      case ApprovalActorRole.customer:
        return activeRole == SystemRole.customer ||
            activeRole == SystemRole.admin;
      case ApprovalActorRole.representative:
        return activeRole == SystemRole.representative ||
            activeRole == SystemRole.customer ||
            activeRole == SystemRole.admin;
      case ApprovalActorRole.foreman:
        return activeRole == SystemRole.contractor;
      case ApprovalActorRole.master:
        return activeRole == SystemRole.master;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCanDecide = ref.watch(
      canInProjectProvider((
        action: DomainAction.approvalDecide,
        projectId: approval.projectId,
      )),
    );
    // П7.7 — фильтр по actorRole: если активная роль не совпадает с ожидаемой
    // ступенью, CTA скрываются. Read-only с плашкой «Ждёт согласования {role}».
    final canDecide = baseCanDecide && _matchesActorRole(ref);
    final canRequest = ref.watch(
      canInProjectProvider((
        action: DomainAction.approvalRequest,
        projectId: approval.projectId,
      )),
    );

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
        // П7.7 — пользователь видит approval, но не может принять решение
        // (его роль не соответствует actorRole активной ступени). Показываем
        // read-only плашку с ожидаемой ролью.
        if (baseCanDecide && approval.actorRole != null) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x16,
              vertical: AppSpacing.x14,
            ),
            decoration: BoxDecoration(
              color: AppColors.n50,
              border: Border(top: BorderSide(color: AppColors.n200)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_top_outlined,
                  size: 18,
                  color: AppColors.n400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ждёт согласования ${approval.actorRole!.displayName}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.n500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.redText,
                  ),
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