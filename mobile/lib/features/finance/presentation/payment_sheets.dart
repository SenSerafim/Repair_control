import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../profile/data/profile_repository.dart';
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
  void initState() {
    super.initState();
    _amount.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amount
      ..removeListener(_onAmountChanged)
      ..dispose();
    _comment.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Перерисовываем status row под input — это live-валидация остатка.
    setState(() {});
  }

  int? get _amountKop => MoneyInput.readKopecks(_amount);
  int get _remainingAfter =>
      widget.parent.remainingToDistribute - (_amountKop ?? 0);
  bool get _exceedsRemaining =>
      (_amountKop ?? 0) > widget.parent.remainingToDistribute;
  bool get _canSubmit =>
      _toUserId != null &&
      (_amountKop ?? 0) > 0 &&
      !_exceedsRemaining &&
      !_submitting;

  Future<void> _submit() async {
    final amountKop = _amountKop;
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
          const SizedBox(height: 6),
          _RemainingHint(
            remainingAfter: _remainingAfter,
            exceeds: _exceedsRemaining,
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
            onPressed: _canSubmit ? _submit : null,
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

/// Диспут по выплате (обязателен reason ≥30 символов по ТЗ §4.4).
Future<bool> showDisputePaymentSheet(
  BuildContext context,
  WidgetRef ref, {
  required Payment payment,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    child: _DisputeBody(payment: payment),
  );
  return result ?? false;
}

class _DisputeBody extends ConsumerStatefulWidget {
  const _DisputeBody({required this.payment});
  final Payment payment;

  @override
  ConsumerState<_DisputeBody> createState() => _DisputeBodyState();
}

class _DisputeBodyState extends ConsumerState<_DisputeBody> {
  /// Минимум содержательных символов в причине (ТЗ §4.4 + §3.3 — не менее
  /// 30, чтобы потом было что разбирать в resolve).
  static const _reasonMinChars = 30;
  static const _maxPhotos = 10;

  final _reason = TextEditingController();
  final List<String> _photoKeys = [];
  bool _submitting = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int get _trimmedLen => _reason.text.trim().length;
  bool get _canSubmit =>
      _trimmedLen >= _reasonMinChars && !_submitting && !_uploading;

  Future<void> _pickAndUpload() async {
    if (_photoKeys.length >= _maxPhotos || _uploading) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final repo = ref.read(profileRepositoryProvider);
      final file = File(picked.path);
      final size = await file.length();
      final name = picked.name;
      final mime = name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final presigned = await repo.presignUpload(
        originalName: name,
        mimeType: mime,
        sizeBytes: size,
        scope: 'payment_dispute',
      );
      final bytes = await file.readAsBytes();
      final raw = Dio();
      await raw.put<void>(
        presigned.url,
        data: bytes,
        options: Options(
          headers: {...presigned.headers, 'Content-Type': mime},
        ),
      );
      if (!mounted) return;
      setState(() => _photoKeys.add(presigned.key));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось загрузить фото');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removePhoto(int i) {
    setState(() => _photoKeys.removeAt(i));
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(
          paymentsControllerProvider(widget.payment.projectId).notifier,
        )
        .dispute(
          id: widget.payment.id,
          reason: _reason.text.trim(),
          photoKeys: _photoKeys.isEmpty ? null : List.unmodifiable(_photoKeys),
        );
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final remaining = _reasonMinChars - _trimmedLen;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
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
              border:
                  Border.all(color: AppColors.redDot.withValues(alpha: 0.3)),
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
          const Text(
            'Причина (минимум 30 символов)',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _reason,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            decoration: _dec(
              'Например, «Перевод не поступил на счёт», '
              '«Сумма не совпадает с актом»…',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              remaining <= 0
                  ? '✓ можно отправлять'
                  : 'осталось $remaining символов',
              style: AppTextStyles.caption.copyWith(
                color: remaining <= 0 ? AppColors.greenDark : AppColors.n400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          // Photo upload (ROAD_TO_100 6.2): presign → PUT → photoKeys[]
          // отправляются в POST /payments/:id/dispute.
          const Text(
            'Фото-доказательства (необязательно, до $_maxPhotos)',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.x6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _photoKeys.length; i++)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border:
                        Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.image_rounded,
                          color: AppColors.brand,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => _removePhoto(i),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.redDot,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: AppColors.n0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_photoKeys.length < _maxPhotos)
                GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.n100,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(
                        color: AppColors.n300,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.n500,
                            ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Открыть спор',
            variant: AppButtonVariant.destructive,
            isLoading: _submitting,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
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

class _RemainingHint extends StatelessWidget {
  const _RemainingHint({
    required this.remainingAfter,
    required this.exceeds,
  });

  final int remainingAfter;
  final bool exceeds;

  @override
  Widget build(BuildContext context) {
    final color = exceeds ? AppColors.redDot : AppColors.n500;
    final label = exceeds
        ? 'Превышение аванса на ${Money.format(-remainingAfter)}'
        : 'Останется ${Money.format(remainingAfter)} после распределения';
    return Row(
      children: [
        Icon(
          exceeds ? Icons.warning_amber_rounded : Icons.info_outline,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: exceeds ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
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

/// «Распределение аванса» — read-only sheet поверх PaymentDetailScreen.
/// Раньше это был полный экран с push в Navigator, что у go_router 14
/// провоцировало `!keyReservation.contains(key)` → `_debugLocked` →
/// мёртвую back-кнопку. Bottom sheet не двигает route stack детайла,
/// swipe-down/back закрывают штатно.
Future<void> showAdvanceDistributionSheet(
  BuildContext context, {
  required Payment parent,
}) {
  return showAppBottomSheet<void>(
    context: context,
    child: _AdvanceDistributionBody(parent: parent),
    isScrollControlled: true,
  );
}

class _AdvanceDistributionBody extends ConsumerWidget {
  const _AdvanceDistributionBody({required this.parent});

  final Payment parent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamControllerProvider(parent.projectId));
    final members = team.valueOrNull?.members ?? const <Membership>[];
    Membership? lookup(String uid) {
      for (final m in members) {
        if (m.userId == uid) return m;
      }
      return null;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(title: 'Распределение аванса'),
          _SummaryCard(payment: parent),
          const SizedBox(height: AppSpacing.x16),
          Text(
            'Распределено мастерам',
            style: AppTextStyles.micro.copyWith(color: AppColors.n400),
          ),
          const SizedBox(height: AppSpacing.x8),
          if (parent.children.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.x16),
              decoration: BoxDecoration(
                color: AppColors.n0,
                border: Border.all(color: AppColors.n200),
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 28,
                    color: AppColors.n400,
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    'Нет выплат',
                    style:
                        AppTextStyles.subtitle.copyWith(color: AppColors.n500),
                  ),
                ],
              ),
            )
          else
            for (final c in parent.children) ...[
              _ChildRow(child: c, member: lookup(c.toUserId)),
              const SizedBox(height: AppSpacing.x8),
            ],
          const SizedBox(height: AppSpacing.x12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.yellowBg,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.yellowText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Заказчик не видит распределение — это внутренняя кухня '
                    'бригадира.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.yellowText,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        border: Border.all(color: AppColors.greenDot.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Получено от заказчика',
            style: AppTextStyles.micro.copyWith(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            Money.format(payment.effectiveAmount),
            style: AppTextStyles.h1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.greenDark,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Распределено: ${Money.format(payment.distributedAmount)} · '
            'Остаток: ${Money.format(payment.remainingToDistribute)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.child, required this.member});

  final Payment child;
  final Membership? member;

  String _name(Membership? m) {
    if (m?.user == null) return 'Мастер';
    return '${m!.user!.firstName} ${m.user!.lastName}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.n200),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.sh1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name(member), style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(
                  child.status.displayName,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.n500),
                ),
              ],
            ),
          ),
          Text(
            Money.format(child.effectiveAmount),
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
            ),
          ),
        ],
      ),
    );
  }
}
