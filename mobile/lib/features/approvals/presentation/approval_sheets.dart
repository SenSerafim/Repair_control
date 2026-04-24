import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/approvals_controller.dart';
import '../domain/approval.dart';

/// d-approve-confirm — подтверждение одобрения.
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
      AppToast.show(
        context,
        message: 'Согласование одобрено',
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
        AppBottomSheetHeader(
          title: 'Одобрить ${widget.approval.scope.displayName.toLowerCase()}?',
          subtitle: 'Вы подтверждаете, что всё ок. Комментарий — '
              'опционально.',
        ),
        if (_error != null) ...[
          _Banner(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        TextField(
          controller: _comment,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          decoration: _textDec('Комментарий (опционально)'),
        ),
        const SizedBox(height: AppSpacing.x12),
        AppButton(
          label: 'Одобрить',
          variant: AppButtonVariant.success,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// d-reject-sheet — отклонение (комментарий обязателен).
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
  final _comment = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _comment.text.trim();
    if (comment.isEmpty) {
      setState(() => _error = 'Объясните причину отклонения');
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
      AppToast.show(
        context,
        message: 'Согласование отклонено',
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
        const AppBottomSheetHeader(
          title: 'Отклонить?',
          subtitle:
              'Комментарий обязателен — он поможет бригаде понять, что поправить.',
        ),
        if (_error != null) ...[
          _Banner(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        TextField(
          controller: _comment,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          decoration: _textDec('Что именно не так?'),
        ),
        const SizedBox(height: AppSpacing.x12),
        AppButton(
          label: 'Отклонить',
          variant: AppButtonVariant.destructive,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// d-resubmit — повторная отправка после отклонения.
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
        AppBottomSheetHeader(
          title: 'Повторить попытку?',
          subtitle:
              'Создаст новую попытку №${widget.approval.attemptNumber + 1}. '
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
    );
