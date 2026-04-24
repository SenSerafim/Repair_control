import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/phone_formatter.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import '../data/team_repository.dart';

/// s-add-member / s-member-found / s-member-not-found — единый flow в
/// bottom-sheet'е.
Future<void> showAddMemberSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
}) async {
  await showAppBottomSheet<void>(
    context: context,
    child: _AddMemberBody(projectId: projectId),
  );
}

class _AddMemberBody extends ConsumerStatefulWidget {
  const _AddMemberBody({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_AddMemberBody> createState() => _AddMemberBodyState();
}

class _AddMemberBodyState extends ConsumerState<_AddMemberBody> {
  final _phone = TextEditingController();
  bool _searching = false;
  bool _submitting = false;
  _FoundState? _result;
  String? _error;
  MembershipRole _role = MembershipRole.master;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final raw = phoneToE164(_phone.text);
    if (!isValidPhoneE164(raw)) {
      setState(() => _error = 'Введите корректный телефон');
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _result = null;
    });
    try {
      final user = await ref.read(teamRepositoryProvider).searchUser(
            projectId: widget.projectId,
            phone: raw,
          );
      if (!mounted) return;
      setState(() {
        _searching = false;
        _result = _FoundState(phone: raw, user: user);
      });
    } on TeamException catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.failure.userMessage;
      });
    }
  }

  Future<void> _addExistingUser() async {
    final result = _result;
    if (result?.user == null) return;
    setState(() => _submitting = true);
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .addMember(userId: result!.user!.id, role: _role);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Добавлен: ${result.user!.firstName}',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  Future<void> _inviteByPhone() async {
    final result = _result;
    if (result == null) return;
    setState(() => _submitting = true);
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .invite(phone: result.phone, role: _role);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Приглашение отправлено',
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
          title: 'Добавить участника',
          subtitle:
              'Введите телефон — если он зарегистрирован, добавим сразу. '
              'Если нет — отправим приглашение.',
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
        const Text('Телефон', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.x6),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          decoration: InputDecoration(
            hintText: '+7 000 000 00 00',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
            filled: true,
            fillColor: AppColors.n0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide:
                  const BorderSide(color: AppColors.n200, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        AppButton(
          label: 'Найти',
          variant: AppButtonVariant.secondary,
          isLoading: _searching,
          onPressed: _search,
        ),
        if (_result != null) ...[
          const SizedBox(height: AppSpacing.x16),
          _ResultBlock(result: _result!),
          const SizedBox(height: AppSpacing.x16),
          const Text('Роль в проекте', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          _RolePicker(
            value: _role,
            onChanged: (r) => setState(() => _role = r),
          ),
          const SizedBox(height: AppSpacing.x16),
          if (_result!.user != null)
            AppButton(
              label: 'Добавить в команду',
              isLoading: _submitting,
              onPressed: _addExistingUser,
            )
          else
            AppButton(
              label: 'Отправить приглашение',
              isLoading: _submitting,
              onPressed: _inviteByPhone,
            ),
        ],
      ],
    );
  }
}

class _FoundState {
  _FoundState({required this.phone, required this.user});
  final String phone;
  final ProjectMemberUser? user;
}

class _ResultBlock extends StatelessWidget {
  const _ResultBlock({required this.result});

  final _FoundState result;

  @override
  Widget build(BuildContext context) {
    if (result.user != null) {
      final u = result.user!;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.greenDot.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.greenDark),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${u.firstName} ${u.lastName}'.trim(),
                    style: AppTextStyles.subtitle
                        .copyWith(color: AppColors.greenDark),
                  ),
                  Text(u.phone, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.yellowDot.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search_outlined, color: AppColors.yellowDot),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              'Номер ${result.phone} не зарегистрирован. '
              'Отправим приглашение — новый пользователь сможет войти '
              'и сразу увидит проект.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.yellowText),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final MembershipRole value;
  final ValueChanged<MembershipRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final roles = [
      MembershipRole.representative,
      MembershipRole.foreman,
      MembershipRole.master,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final r in roles)
          GestureDetector(
            onTap: () => onChanged(r),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x12,
                vertical: AppSpacing.x8,
              ),
              decoration: BoxDecoration(
                color: value == r ? AppColors.brand : AppColors.n100,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                r.displayName,
                style: AppTextStyles.caption.copyWith(
                  color: value == r ? AppColors.n0 : AppColors.n700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
