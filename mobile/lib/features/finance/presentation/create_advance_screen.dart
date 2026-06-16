import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/domain/membership.dart';
import '../../projects/presentation/money_input.dart';
import '../../stages/application/stages_controller.dart';
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
  String? _stageId;
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
          stageId: _stageId,
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
                final totalMembers = team.members.length;
                final foremenAll = team.members
                    .where((m) => m.role == MembershipRole.foreman)
                    .length;
                final mastersAll = team.members
                    .where((m) => m.role == MembershipRole.master)
                    .length;
                // Если в команде кто-то есть, но они — это вы сами
                // (legacy: customer-owner с дублирующей foreman-ролью),
                // показываем диагностику. Иначе — стандартное приглашение.
                final selfBlocks = (foremenAll > 0 || mastersAll > 0);
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: AppColors.yellowBg,
                    borderRadius: AppRadius.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        selfBlocks
                            ? 'Нет получателей кроме вас самих '
                                  '(в команде: бригадиров — $foremenAll, '
                                  'мастеров — $mastersAll, всего — $totalMembers). '
                                  'Аванс самому себе перевести нельзя.'
                            : 'В команде нет бригадиров и мастеров. '
                                  'Пригласите их в проекте.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.yellowText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x10),
                      _AddRecipientBar(projectId: widget.projectId),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NEWFIX TZ-2 §5 — быстрая кнопка «Добавить получателя»
                  // прямо в форме (чтобы не возвращаться в Команду проекта).
                  _AddRecipientBar(projectId: widget.projectId),
                  const SizedBox(height: AppSpacing.x12),
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
          // ТЗ §4: к каждой выплате опционально привязывается этап,
          // чтобы потом можно было видеть «бюджет этапа» и историю по нему.
          // В форме расхода селектор есть, тут добавляем для симметрии.
          const Text('Этап (опционально)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          _StagePickerAdvance(
            projectId: widget.projectId,
            selectedStageId: _stageId,
            onChanged: (id) => setState(() => _stageId = id),
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

/// Селектор этапа для формы аванса. Аналогичен `_StagePicker` из
/// add_expense_sheet, но локальный (избегаем циклов между модулями).
class _StagePickerAdvance extends ConsumerWidget {
  const _StagePickerAdvance({
    required this.projectId,
    required this.selectedStageId,
    required this.onChanged,
  });

  final String projectId;
  final String? selectedStageId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stagesControllerProvider(projectId));
    return async.when(
      loading: () => const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Text(
        'Не удалось загрузить этапы',
        style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
      ),
      data: (stages) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ChoiceChip(
            label: const Text('Без этапа'),
            selected: selectedStageId == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final s in stages)
            ChoiceChip(
              label: Text('Этап ${s.orderIndex + 1}'),
              selected: selectedStageId == s.id,
              onSelected: (_) => onChanged(s.id),
            ),
        ],
      ),
    );
  }
}

/// Кнопка-плашка «Добавить получателя в проект» прямо в форме аванса:
/// открывает существующий flow `/projects/:id/team/add`.
class _AddRecipientBar extends StatelessWidget {
  const _AddRecipientBar({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Добавить получателя',
      icon: Icons.person_add_alt_1_rounded,
      variant: AppButtonVariant.ghost,
      onPressed: () =>
          context.push(AppRoutes.projectAddMemberWith(projectId)),
    );
  }
}
