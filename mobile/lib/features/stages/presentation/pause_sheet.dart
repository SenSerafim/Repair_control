import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/stages_controller.dart';
import '../domain/pause_reason.dart';

/// Двухшаговый Pause-flow по дизайну c-pause-sheet → c-pause-confirm-*.
///
/// 1. PausePickerSheet: 4 цветные опции причин.
/// 2. PauseConfirmSheet: цветной confirm (yellow/purple/red/textarea для other).
///
/// Хост-экран вызывает [showPauseSheet] и получает `true`, если этап
/// действительно поставлен на паузу.
Future<bool> showPauseSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String stageId,
  required String stageTitle,
}) async {
  final reason = await _showPausePickerSheet(context);
  if (reason == null) return false;
  if (!context.mounted) return false;

  final result = await _showPauseConfirmSheet(
    context,
    ref,
    projectId: projectId,
    stageId: stageId,
    stageTitle: stageTitle,
    reason: reason,
  );
  return result;
}

// ─────────────────────────────────────────────────────────────────────
// Шаг 1: picker — 4 цветные опции
// ─────────────────────────────────────────────────────────────────────
Future<PauseReason?> _showPausePickerSheet(BuildContext context) async {
  return showAppBottomSheet<PauseReason>(
    context: context,
    child: const _PickerBody(),
  );
}

class _PickerBody extends StatelessWidget {
  const _PickerBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Приостановить этап',
          subtitle:
              'Выберите причину паузы. Дедлайн будет сдвинут автоматически.',
        ),
        for (var i = 0; i < PauseReason.values.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: AppColors.n100),
          _ReasonRow(
            reason: PauseReason.values[i],
            onTap: () =>
                Navigator.of(context).pop(PauseReason.values[i]),
          ),
        ],
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.reason, required this.onTap});

  final PauseReason reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = _palette(reason);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: spec.bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(reason.icon, size: 20, color: spec.fg),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Text(
                reason.displayName,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.n300,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Шаг 2: confirm — цветная sheet'а в зависимости от причины
// ─────────────────────────────────────────────────────────────────────
Future<bool> _showPauseConfirmSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String stageId,
  required String stageTitle,
  required PauseReason reason,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _ConfirmBody(
      projectId: projectId,
      stageId: stageId,
      stageTitle: stageTitle,
      reason: reason,
    ),
  );
  return result ?? false;
}

class _ConfirmBody extends ConsumerStatefulWidget {
  const _ConfirmBody({
    required this.projectId,
    required this.stageId,
    required this.stageTitle,
    required this.reason,
  });

  final String projectId;
  final String stageId;
  final String stageTitle;
  final PauseReason reason;

  @override
  ConsumerState<_ConfirmBody> createState() => _ConfirmBodyState();
}

class _ConfirmBodyState extends ConsumerState<_ConfirmBody> {
  static const _otherCommentMinChars = 10;
  final _comment = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _commentRequired => widget.reason == PauseReason.other;
  bool get _canSubmit {
    if (!_commentRequired) return true;
    return _comment.text.trim().length >= _otherCommentMinChars;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(stagesControllerProvider(widget.projectId).notifier)
        .pause(
          stageId: widget.stageId,
          reason: widget.reason,
          comment:
              _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Этап на паузе',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _palette(widget.reason);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: spec.bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              alignment: Alignment.center,
              child: Icon(widget.reason.icon, size: 22, color: spec.fg),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.reason.displayName,
                    style: AppTextStyles.h1.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Этап «${widget.stageTitle}» будет приостановлен.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x16),
        if (_commentRequired) ...[
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 6,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'В чём причина паузы? (минимум 10 символов)',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: BorderSide(color: spec.fg, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              () {
                final remaining =
                    _otherCommentMinChars - _comment.text.trim().length;
                if (remaining <= 0) return '✓ можно отправлять';
                return 'осталось $remaining';
              }(),
              style: AppTextStyles.caption.copyWith(
                color:
                    _comment.text.trim().length >= _otherCommentMinChars
                        ? AppColors.greenDark
                        : AppColors.n400,
              ),
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: spec.bg,
              borderRadius: AppRadius.card,
            ),
            child: Text(
              widget.reason == PauseReason.forceMajeure
                  ? '⚠ Форс-мажор фиксируется в ленте событий как неизменяемая запись. Заказчик может принять причину или оспорить.'
                  : 'Дедлайн этапа сдвинется автоматически на время паузы. Заказчик получит уведомление с указанной причиной.',
              style: AppTextStyles.caption.copyWith(
                color: spec.fg,
                height: 1.5,
              ),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.x12),
          AppInlineError(message: _error!),
        ],
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: widget.reason == PauseReason.forceMajeure
              ? 'Приостановить (форс-мажор)'
              : 'Приостановить этап',
          variant: AppButtonVariant.destructive,
          isLoading: _submitting,
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Назад',
          variant: AppButtonVariant.ghost,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

({Color bg, Color fg}) _palette(PauseReason r) {
  return switch (r) {
    PauseReason.materials => (
        bg: AppColors.yellowBg,
        fg: AppColors.yellowText,
      ),
    PauseReason.approval => (
        bg: AppColors.purpleBg,
        fg: AppColors.purple,
      ),
    PauseReason.forceMajeure => (
        bg: AppColors.redBg,
        fg: AppColors.redText,
      ),
    PauseReason.other => (
        bg: AppColors.n100,
        fg: AppColors.n600,
      ),
  };
}
