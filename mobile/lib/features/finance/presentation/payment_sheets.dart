import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/domain/membership.dart';
import '../../projects/presentation/money_input.dart';
import '../../team/application/team_controller.dart';
import '../application/payments_controller.dart';
import '../domain/payment.dart';

/// Распределение advance на master'а. Единственный bottom-sheet, который
/// остался после удаления FSM статусов (2026-05-12).
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

/// Простая выплата мастеру из «кассы бригадира» — без выбора parent-аванса.
/// Открывается primary-кнопкой на BudgetScreen у бригадира.
/// [available] — текущий доступный остаток кассы (advancesReceived − distributed).
/// Может быть отрицательным; запрет на ввод суммы больше available — не
/// блокируем (по ТЗ §4.2 бригадир может «уйти в минус» из карманных).
Future<bool> showPayMasterFromWalletSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required int available,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _PayFromWalletBody(projectId: projectId, available: available),
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
        .read(paymentsControllerProvider(widget.parent.projectId).notifier)
        .distribute(
          parentPaymentId: widget.parent.id,
          toUserId: _toUserId!,
          amount: amountKop,
          stageId: widget.parent.stageId,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
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
    final teamAsync = ref.watch(
      teamControllerProvider(widget.parent.projectId),
    );
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
                style: AppTextStyles.body.copyWith(color: AppColors.redText),
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
              style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
            ),
            data: (team) {
              // Бригадир не должен мочь distribute самому себе, даже если
              // числится мастером в этом же проекте через legacy membership.
              // Бекенд зеркалит запрет (PAYMENT_SELF_PAYMENT_FORBIDDEN).
              final meId = ref.watch(authControllerProvider).userId;
              final masters = team.members
                  .where(
                    (m) => m.role == MembershipRole.master && m.userId != meId,
                  )
                  .toList();
              if (masters.isEmpty) {
                return Text(
                  'В проекте нет мастеров.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.yellowText,
                  ),
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
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x8,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.brandButton : null,
          color: selected ? null : AppColors.n100,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x524F6EF7),
                    offset: Offset(0, 4),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.n0 : AppColors.n700,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _RemainingHint extends StatelessWidget {
  const _RemainingHint({required this.remainingAfter, required this.exceeds});

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
/// Bottom sheet вместо push, чтобы не двигать route stack детайла.
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
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.n500,
                    ),
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
            Money.format(payment.amount),
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

class _PayFromWalletBody extends ConsumerStatefulWidget {
  const _PayFromWalletBody({required this.projectId, required this.available});

  final String projectId;
  final int available;

  @override
  ConsumerState<_PayFromWalletBody> createState() => _PayFromWalletBodyState();
}

class _PayFromWalletBodyState extends ConsumerState<_PayFromWalletBody> {
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

  void _onAmountChanged() => setState(() {});

  int? get _amountKop => MoneyInput.readKopecks(_amount);
  int get _afterPayout => widget.available - (_amountKop ?? 0);
  bool get _exceedsWallet => (_amountKop ?? 0) > widget.available;
  bool get _canSubmit =>
      _toUserId != null && (_amountKop ?? 0) > 0 && !_submitting;

  Future<void> _submit() async {
    final amountKop = _amountKop;
    if (amountKop == null || amountKop <= 0) {
      setState(() => _error = 'Укажите сумму');
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
        .read(paymentsControllerProvider(widget.projectId).notifier)
        .distributeFromWallet(
          toUserId: _toUserId!,
          amount: amountKop,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Выплата мастеру отправлена',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamControllerProvider(widget.projectId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBottomSheetHeader(
            title: 'Выплатить мастеру',
            subtitle: 'Доступно в кассе: ${Money.format(widget.available)}',
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
                style: AppTextStyles.body.copyWith(color: AppColors.redText),
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
              style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
            ),
            data: (team) {
              final meId = ref.watch(authControllerProvider).userId;
              final masters = team.members
                  .where(
                    (m) => m.role == MembershipRole.master && m.userId != meId,
                  )
                  .toList();
              if (masters.isEmpty) {
                return Text(
                  'В проекте нет мастеров. Пригласите их во вкладке «Команда».',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.yellowText,
                  ),
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
            hint: 'Сколько перевести',
          ),
          const SizedBox(height: 6),
          _WalletAfterHint(afterPayout: _afterPayout, exceeds: _exceedsWallet),
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

class _WalletAfterHint extends StatelessWidget {
  const _WalletAfterHint({required this.afterPayout, required this.exceeds});

  final int afterPayout;
  final bool exceeds;

  @override
  Widget build(BuildContext context) {
    final color = exceeds ? AppColors.yellowText : AppColors.n500;
    final label = exceeds
        ? 'Касса уйдёт в минус на ${Money.format(-afterPayout)}'
        : 'Останется ${Money.format(afterPayout)} в кассе';
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
          Expanded(child: Text(_name(member), style: AppTextStyles.subtitle)),
          Text(
            Money.format(child.amount),
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
