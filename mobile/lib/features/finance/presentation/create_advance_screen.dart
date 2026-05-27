import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/domain/membership.dart';
import '../../projects/presentation/money_input.dart';
import '../../team/application/team_controller.dart';
import '../application/payments_controller.dart';

/// e-advance / s-budget-advance / e-pay-new — создание аванса бригадиру.
class CreateAdvanceScreen extends ConsumerStatefulWidget {
  const CreateAdvanceScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CreateAdvanceScreen> createState() =>
      _CreateAdvanceScreenState();
}

class _CreateAdvanceScreenState extends ConsumerState<CreateAdvanceScreen> {
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
      setState(() => _error = 'Укажите сумму аванса');
      return;
    }
    if (_toUserId == null) {
      setState(() => _error = 'Выберите получателя');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(paymentsControllerProvider(widget.projectId).notifier)
        .createAdvance(
          toUserId: _toUserId!,
          amount: amountKop,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      AppToast.show(
        context,
        message: 'Аванс отправлен',
        kind: AppToastKind.success,
      );
      context.pop();
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamControllerProvider(widget.projectId));
    return AppScaffold(
      showBack: true,
      title: 'Новый аванс',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.x16),
          const Text(
            'Аванс можно отправить бригадиру (он распределит мастерам) '
            'или напрямую мастеру. Прямая выплата мастеру будет видна бригадиру '
            'в общей истории движений — прозрачность сохраняется.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x16),
          if (_error != null) ...[
            AppInlineError(message: _error!),
            const SizedBox(height: AppSpacing.x12),
          ],
          teamAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.x12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text(
              'Не удалось загрузить команду',
              style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
            ),
            data: (team) {
              // Защита от self-payment на UI-уровне: даже если заказчик
              // числится в проекте бригадиром/мастером по legacy membership —
              // показывать его себе в списке получателей нельзя. Сервер
              // зеркалит запрет (PAYMENT_SELF_PAYMENT_FORBIDDEN).
              final meId = ref.watch(authControllerProvider).userId;
              final foremen = team.members
                  .where(
                    (m) => m.role == MembershipRole.foreman && m.userId != meId,
                  )
                  .toList();
              final masters = team.members
                  .where(
                    (m) => m.role == MembershipRole.master && m.userId != meId,
                  )
                  .toList();
              if (foremen.isEmpty && masters.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: AppColors.yellowBg,
                    borderRadius: AppRadius.card,
                  ),
                  child: Text(
                    'В команде нет бригадиров и мастеров. Пригласите их в проекте.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.yellowText,
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (foremen.isNotEmpty) ...[
                    const Text('Бригадир', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.x6),
                    for (final m in foremen) ...[
                      _RecipientTile(
                        name: _nameOf(m),
                        phone: m.user?.phone,
                        selected: _toUserId == m.userId,
                        onTap: () => setState(() => _toUserId = m.userId),
                      ),
                      const SizedBox(height: AppSpacing.x8),
                    ],
                  ],
                  if (masters.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x8),
                    const Text(
                      'Мастера (прямая выплата)',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    for (final m in masters) ...[
                      _RecipientTile(
                        name: _nameOf(m),
                        phone: m.user?.phone,
                        selected: _toUserId == m.userId,
                        onTap: () => setState(() => _toUserId = m.userId),
                      ),
                      const SizedBox(height: AppSpacing.x8),
                    ],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x16),
          MoneyInput(
            controller: _amount,
            label: 'Сумма аванса',
            hint: 'Сколько переводите',
          ),
          const SizedBox(height: AppSpacing.x16),
          const Text('Комментарий (опционально)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Например, «Аванс за демонтаж»',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x24),
          AppButton(
            label: 'Отправить аванс',
            isLoading: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.x16),
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

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.name,
    required this.selected,
    required this.onTap,
    this.phone,
  });

  final String name;
  final String? phone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.brandLight,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.subtitle.copyWith(color: AppColors.brand),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.subtitle),
                  if (phone != null) Text(phone!, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}
