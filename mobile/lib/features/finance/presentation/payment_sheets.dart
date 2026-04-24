import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../projects/presentation/money_input.dart';
import '../../team/application/team_controller.dart';
import '../application/payments_controller.dart';
import '../domain/payment.dart';

/// Распределение advance на master'а.
Future<bool> showDistributeSheet(
  BuildContext context,
  WidgetRef ref, {
  required Payment parent,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _DistributeBody(parent: parent),
    isScrollControlled: true,
  );
  return result ?? false;
}

class _DistributeBody extends ConsumerStatefulWidget {
  const _DistributeBody({required this.parent});
  final Payment parent;

  @override
  ConsumerState<_DistributeBody> createState() => _DistributeBodyState();
}

class _DistributeBodyState extends ConsumerState<_DistributeBody> {
  final _amount = TextEditingController();
  final _comment = TextEditingController();
  String? _toUserId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountKop = MoneyInput.readKopecks(_amount);
    if (amountKop == null || amountKop <= 0) {
      setState(() => _error = 'Укажите сумму');
      return;
    }
    if (amountKop > widget.parent.remainingToDistribute) {
      setState(
        () => _error =
            'Больше, чем остаток (${Money.format(widget.parent.remainingToDistribute)})',
      );
      return;
    }
    if (_toUserId == null) {
      setState(() => _error = 'Выберите мастера');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(
          paymentsControllerProvider(widget.parent.projectId).notifier,
        )
        .distribute(
          parentPaymentId: widget.parent.id,
          toUserId: _toUserId!,
          amount: amountKop,
          stageId: widget.parent.stageId,
          comment:
              _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Выплата мастеру создана',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync =
        ref.watch(teamControllerProvider(widget.parent.projectId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBottomSheetHeader(
            title: 'Выплата мастеру',
            subtitle:
                'Доступный остаток: ${Money.format(widget.parent.remainingToDistribute)}',
          ),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.x12),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: AppRadius.card,
              ),
              child: Text(
                _error!,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.redText),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          const Text('Мастер', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          teamAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Не удалось загрузить команду',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.redDot),
            ),
            data: (team) {
              final masters = team.members
                  .where((m) => m.role == MembershipRole.master)
                  .toList();
              if (masters.isEmpty) {
                return Text(
                  'В проекте нет мастеров.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.yellowText),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in masters)
                    _Chip(
                      label: _nameOf(m),
                      selected: _toUserId == m.userId,
                      onTap: () => setState(() => _toUserId = m.userId),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x12),
          MoneyInput(
            controller: _amount,
            label: 'Сумма',
            hint: 'Не больше остатка',
          ),
          const SizedBox(height: AppSpacing.x12),
          const Text('Комментарий', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 2000,
            decoration: _dec('Опционально'),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Отправить',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  String _nameOf(Membership m) {
    final u = m.user;
    if (u == null) return m.role.displayName;
    final full = '${u.firstName} ${u.lastName}'.trim();
    return full.isEmpty ? m.role.displayName : full;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.n100,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.n0 : AppColors.n700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Диспут по выплате (обязателен reason).
Future<bool> showDisputePaymentSheet(
  BuildContext context,
  WidgetRef ref, {
  required Payment payment,
}) async {
  final reasonController = TextEditingController();
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _DisputeBody(
      payment: payment,
      controller: reasonController,
    ),
  );
  reasonController.dispose();
  return result ?? false;
}

class _DisputeBody extends ConsumerStatefulWidget {
  const _DisputeBody({required this.payment, required this.controller});
  final Payment payment;
  final TextEditingController controller;

  @override
  ConsumerState<_DisputeBody> createState() => _DisputeBodyState();
}

class _DisputeBodyState extends ConsumerState<_DisputeBody> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final reason = widget.controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Опишите причину спора');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(
          paymentsControllerProvider(widget.payment.projectId).notifier,
        )
        .dispute(id: widget.payment.id, reason: reason);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Спор открыт',
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
          title: 'Открыть спор',
          subtitle:
              'Расскажите, что не так. Это заморозит выплату до разрешения.',
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            color: AppColors.redBg,
            border: Border.all(color: const Color(0xFFFECACA)),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.report_problem_outlined,
                size: 16,
                color: AppColors.redDot,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Другая сторона получит push-уведомление',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.redDot,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        if (_error != null) ...[
          AppInlineError(message: _error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        TextField(
          controller: widget.controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          decoration: _dec('Например, «Сумма не совпадает»'),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Открыть спор',
          variant: AppButtonVariant.destructive,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Разрешение спора — resolution + optional adjustAmount.
Future<bool> showResolvePaymentSheet(
  BuildContext context,
  WidgetRef ref, {
  required Payment payment,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _ResolveBody(payment: payment),
    isScrollControlled: true,
  );
  return result ?? false;
}

class _ResolveBody extends ConsumerStatefulWidget {
  const _ResolveBody({required this.payment});
  final Payment payment;

  @override
  ConsumerState<_ResolveBody> createState() => _ResolveBodyState();
}

class _ResolveBodyState extends ConsumerState<_ResolveBody> {
  final _resolution = TextEditingController();
  final _adjust = TextEditingController();
  bool _adjustEnabled = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _resolution.dispose();
    _adjust.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _resolution.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Опишите решение');
      return;
    }
    final adjust =
        _adjustEnabled ? MoneyInput.readKopecks(_adjust) : null;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(
          paymentsControllerProvider(widget.payment.projectId).notifier,
        )
        .resolve(
          id: widget.payment.id,
          resolution: text,
          adjustAmount: adjust,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Спор разрешён',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(
            title: 'Разрешить спор',
            subtitle:
                'Опишите решение. При необходимости — скорректируйте сумму.',
          ),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.x12),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: AppRadius.card,
              ),
              child: Text(
                _error!,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.redText),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          TextField(
            controller: _resolution,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: _dec('Как разрешили'),
          ),
          const SizedBox(height: AppSpacing.x12),
          SwitchListTile(
            value: _adjustEnabled,
            onChanged: (v) => setState(() => _adjustEnabled = v),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Скорректировать сумму',
              style: AppTextStyles.subtitle,
            ),
            subtitle: const Text(
              'Окончательная сумма платежа',
              style: AppTextStyles.caption,
            ),
          ),
          if (_adjustEnabled) ...[
            MoneyInput(
              controller: _adjust,
              label: 'Итоговая сумма',
            ),
            const SizedBox(height: AppSpacing.x10),
          ],
          AppButton(
            label: 'Разрешить',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

InputDecoration _dec(String hint) => InputDecoration(
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
