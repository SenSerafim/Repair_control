import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/approvals_controller.dart';
import '../domain/approval.dart';

/// Цветовая палитра для круглой иконки sheet'а.
enum _IconTone { success, danger, info }

class _SheetIconHeader extends StatelessWidget {
  const _SheetIconHeader({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final _IconTone tone;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _IconTone.success => (AppColors.greenLight, AppColors.greenDark),
      _IconTone.danger => (AppColors.redBg, AppColors.redDot),
      _IconTone.info => (AppColors.brandLight, AppColors.brand),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: 28),
        ),
        const SizedBox(height: AppSpacing.x14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.n500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.x20),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.redText),
      ),
    );
  }
}

InputDecoration _textDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
      filled: true,
      fillColor: AppColors.n0,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    );

void _navigateResult(
  BuildContext context, {
  required Approval approval,
  required ApprovalStatus status,
}) {
  context.replace(
    AppRoutes.approvalResultWith(
      approval.projectId,
      approval.id,
      status.apiValue,
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────
// Approve  (d-approve-confirm)
// ──────────────────────────────────────────────────────────────────────

Future<bool> showApproveSheet(
  BuildContext context,
  WidgetRef ref, {
  required Approval approval,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _ApproveBody(approval: approval),
  );
  return result ?? false;
}

class _ApproveBody extends ConsumerStatefulWidget {
  const _ApproveBody({required this.approval});

  final Approval approval;

  @override
  ConsumerState<_ApproveBody> createState() => _ApproveBodyState();
}

class _ApproveBodyState extends ConsumerState<_ApproveBody> {
  final _comment = TextEditingController();
  bool _submitting = false;
  bool _showComment = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(
          approvalsControllerProvider(widget.approval.projectId).notifier,
        )
        .approve(
          approval: widget.approval,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      _navigateResult(
        context,
        approval: widget.approval,
        status: ApprovalStatus.approved,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetIconHeader(
          icon: Icons.check_rounded,
          tone: _IconTone.success,
          title: 'Одобрить работу?',
          subtitle: 'Подтвердите, что работа выполнена корректно. '
              'После одобрения изменения попадут в проект.',
        ),
        if (_error != null) ...[
          _Banner(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        if (_showComment) ...[
          TextField(
            controller: _comment,
            minLines: 2,
            maxLines: 4,
            maxLength: 2000,
            decoration: _textDec('Комментарий (опционально)'),
          ),
          const SizedBox(height: AppSpacing.x10),
        ] else ...[
          GestureDetector(
            onTap: () => setState(() => _showComment = true),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    color: AppColors.brand,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Добавить комментарий',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.brand,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
        ],
        AppButton(
          label: 'Да, одобрить',
          variant: AppButtonVariant.success,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.ghost,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Reject  (d-reject-sheet)
// ──────────────────────────────────────────────────────────────────────

Future<bool> showRejectSheet(
  BuildContext context,
  WidgetRef ref, {
  required Approval approval,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _RejectBody(approval: approval),
  );
  return result ?? false;
}

class _RejectBody extends ConsumerStatefulWidget {
  const _RejectBody({required this.approval});

  final Approval approval;

  @override
  ConsumerState<_RejectBody> createState() => _RejectBodyState();
}

class _RejectBodyState extends ConsumerState<_RejectBody> {
  static const int _minLength = 10;
  final _comment = TextEditingController();
  bool _submitting = false;
  String? _error;
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() {
      final l = _comment.text.trim().length;
      if (l != _length) setState(() => _length = l);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _comment.text.trim();
    if (comment.length < _minLength) {
      setState(() => _error =
          'Объясните причину отклонения (минимум $_minLength символов)');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(
          approvalsControllerProvider(widget.approval.projectId).notifier,
        )
        .reject(approval: widget.approval, comment: comment);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      _navigateResult(
        context,
        approval: widget.approval,
        status: ApprovalStatus.rejected,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _length >= _minLength && !_submitting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetIconHeader(
          icon: Icons.close_rounded,
          tone: _IconTone.danger,
          title: 'Отклонить работу?',
          subtitle: 'Опишите, что нужно исправить. Бригада увидит ваш '
              'комментарий и сможет переотправить.',
        ),
        if (_error != null) ...[
          _Banner(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'ФОТО',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n400,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x8),
        const Row(
          children: [
            _PhotoSlot(icon: Icons.camera_alt_outlined),
            SizedBox(width: 8),
            _PhotoSlot(icon: Icons.add_rounded),
          ],
        ),
        const SizedBox(height: AppSpacing.x14),
        TextField(
          controller: _comment,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          decoration: _textDec('Что нужно исправить...'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _length < _minLength
                ? 'Ещё ${_minLength - _length} симв.'
                : 'OK',
            style: AppTextStyles.tiny.copyWith(
              color: _length < _minLength
                  ? AppColors.redText
                  : AppColors.greenDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        AppButton(
          label: 'Отклонить',
          variant: AppButtonVariant.destructive,
          isLoading: _submitting,
          onPressed: canSubmit ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.ghost,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Загрузка фото скоро будет доступна',
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.n100,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.n200),
        ),
        child: Icon(icon, color: AppColors.n400, size: 22),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Resubmit
// ──────────────────────────────────────────────────────────────────────

Future<bool> showResubmitSheet(
  BuildContext context,
  WidgetRef ref, {
  required Approval approval,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _ResubmitBody(approval: approval),
  );
  return result ?? false;
}

class _ResubmitBody extends ConsumerStatefulWidget {
  const _ResubmitBody({required this.approval});

  final Approval approval;

  @override
  ConsumerState<_ResubmitBody> createState() => _ResubmitBodyState();
}

class _ResubmitBodyState extends ConsumerState<_ResubmitBody> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(
          approvalsControllerProvider(widget.approval.projectId).notifier,
        )
        .resubmit(approval: widget.approval);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Отправлено повторно',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetIconHeader(
          icon: Icons.refresh_rounded,
          tone: _IconTone.info,
          title: 'Повторить попытку?',
          subtitle:
              'Будет создана попытка №${widget.approval.attemptNumber + 1}. '
              'Сначала устраните замечания из предыдущего отказа.',
        ),
        if (_error != null) ...[
          _Banner(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        AppButton(
          label: 'Отправить повторно',
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.ghost,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
