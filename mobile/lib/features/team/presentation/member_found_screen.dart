import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import 'add_member_screen.dart';

/// s-member-found — карточка найденного пользователя + role picker.
///
/// 2026-05 рефактор:
///   • Role picker фильтруется через `invitableRolesProvider` (membership-роль
///     текущего пользователя в этом проекте).
///   • Если найденный юзер уже в команде — баннер «уже в команде как X»
///     вместо CTA, чтобы не получать 409 от backend.
///   • Master → следующий шаг `AssignStageScreen` (выбор этапа или
///     добавление без этапа). Foreman/representative → добавляются в проект
///     напрямую; права представителя настраиваются в карточке участника.
class MemberFoundScreen extends ConsumerStatefulWidget {
  const MemberFoundScreen({
    required this.projectId,
    required this.args,
    super.key,
  });

  final String projectId;
  final MemberFoundArgs args;

  @override
  ConsumerState<MemberFoundScreen> createState() => _MemberFoundScreenState();
}

class _MemberFoundScreenState extends ConsumerState<MemberFoundScreen> {
  MembershipRole? _role;
  String? _specialization;
  bool _busy = false;

  Future<void> _submit() async {
    final role = _role;
    if (role == null) return;

    // Master — опциональная привязка к этапу делается вторым шагом.
    if (role == MembershipRole.master) {
      context.push(
        AppRoutes.projectAssignStageWith(widget.projectId),
        extra: widget.args.copyWith(specialization: _specialization),
      );
      return;
    }

    setState(() => _busy = true);
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .addMember(userId: widget.args.userId, role: role);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      final suffix = role == MembershipRole.representative
          ? '. Настройте права в карточке участника.'
          : '';
      AppToast.show(
        context,
        message:
            '✓ ${widget.args.firstName} добавлен(а) ${_addedLabel(role)}'
            '$suffix',
        kind: AppToastKind.success,
      );
      context.go(AppRoutes.projectTeamWith(widget.projectId));
    } else {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  String _addedLabel(MembershipRole role) {
    switch (role) {
      case MembershipRole.foreman:
        return 'бригадиром';
      case MembershipRole.master:
        return 'мастером';
      case MembershipRole.representative:
        return 'представителем';
      case MembershipRole.customer:
        return 'заказчиком';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(invitableRolesProvider(widget.projectId));
    final teamAsync = ref.watch(teamControllerProvider(widget.projectId));
    final existingRole = teamAsync.maybeWhen<MembershipRole?>(
      data: (team) {
        try {
          return team.members
              .firstWhere((m) => m.userId == widget.args.userId)
              .role;
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    // Дефолт — первая доступная роль.
    if (_role == null && allowed.isNotEmpty && existingRole == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _role = allowed.first);
      });
    }

    final fullName = '${widget.args.firstName} ${widget.args.lastName}'.trim();

    return AppScaffold(
      showBack: true,
      title: 'Назначение',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
        children: [
          _UserCard(args: widget.args, fullName: fullName),
          const SizedBox(height: AppSpacing.x20),
          if (existingRole != null)
            _AlreadyInTeamCard(role: existingRole, name: widget.args.firstName)
          else if (allowed.isEmpty)
            const _NoRightsCard()
          else ...[
            const Text(
              'РОЛЬ В ПРОЕКТЕ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.n400,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            for (final r in allowed) ...[
              _RoleRow(
                role: r,
                selected: _role == r,
                onTap: () => setState(() {
                  _role = r;
                  if (r != MembershipRole.master) _specialization = null;
                }),
              ),
              const SizedBox(height: AppSpacing.x8),
            ],
            const SizedBox(height: AppSpacing.x6),
            _HintBox(text: _hintFor(_role)),
            if (_role == MembershipRole.master) ...[
              const SizedBox(height: AppSpacing.x16),
              const Text(
                'СПЕЦИАЛИЗАЦИЯ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              _SpecializationPicker(
                value: _specialization,
                onChanged: (value) => setState(() => _specialization = value),
              ),
            ],
            const SizedBox(height: AppSpacing.x20),
            AppButton(
              label: _role == MembershipRole.master
                  ? 'Далее: выбрать этап'
                  : 'Добавить ${_addedLabel(_role ?? MembershipRole.foreman)}',
              variant: AppButtonVariant.success,
              isLoading: _busy,
              onPressed: _role == null ? null : _submit,
            ),
          ],
        ],
      ),
    );
  }

  static String _hintFor(MembershipRole? r) {
    switch (r) {
      case MembershipRole.foreman:
        return 'Бригадир ведёт этапы целиком: назначает мастеров, '
            'отправляет согласования, получает и распределяет авансы.';
      case MembershipRole.master:
        return 'Мастер работает на выбранных этапах: отмечает шаги, '
            'прикладывает фото, задаёт вопросы. На следующем шаге '
            'выберите этап (или добавьте без этапа).';
      case MembershipRole.representative:
        return 'Представитель действует от имени заказчика по выданным '
            'правам. Конкретные права настроите в карточке участника.';
      case MembershipRole.customer:
      case null:
        return 'Выберите роль участника в этом проекте.';
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.args, required this.fullName});

  final MemberFoundArgs args;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.n200),
        borderRadius: BorderRadius.circular(AppRadius.r20),
        boxShadow: AppShadows.sh1,
      ),
      child: Row(
        children: [
          AppAvatar(
            seed: args.userId,
            name: fullName,
            size: 52,
            palette: AvatarPalette.yellow,
          ),
          const SizedBox(width: AppSpacing.x14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  args.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.greenDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Зарегистрирован',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final MembershipRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, sub) = _present();
    return Material(
      color: selected ? AppColors.brandLight : AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.n200,
              width: 1.5,
            ),
            borderRadius: AppRadius.card,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.n0 : AppColors.n100,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsRegular.circle,
                size: 22,
                color: selected ? AppColors.brand : AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, String, String) _present() {
    switch (role) {
      case MembershipRole.foreman:
        return (
          PhosphorIconsRegular.briefcase,
          AppColors.brand,
          'Бригадир',
          'Ведёт этапы целиком',
        );
      case MembershipRole.master:
        return (
          PhosphorIconsRegular.wrench,
          AppColors.purple,
          'Мастер',
          'Работает на выбранных этапах',
        );
      case MembershipRole.representative:
        return (
          PhosphorIconsRegular.userCircle,
          AppColors.yellowText,
          'Представитель',
          'Действует от имени заказчика',
        );
      case MembershipRole.customer:
        return (
          PhosphorIconsRegular.crown,
          AppColors.n600,
          'Заказчик',
          'Владелец проекта',
        );
    }
  }
}

class _AlreadyInTeamCard extends StatelessWidget {
  const _AlreadyInTeamCard({required this.role, required this.name});

  final MembershipRole role;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsFill.checkCircle, color: AppColors.brand, size: 24),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              '$name уже в команде как «${role.displayName}». '
              'Чтобы изменить роль — снимите текущую в карточке участника.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRightsCard extends StatelessWidget {
  const _NoRightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.yellowDot.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.warning, color: AppColors.yellowText),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              'У вашей роли нет права приглашать в этот проект.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.yellowText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecializationPicker extends StatelessWidget {
  const _SpecializationPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _values = [
    'Плиточник',
    'Сантехник',
    'Электрик',
    'Широкого профиля',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in _values)
          ChoiceChip(
            label: Text(item),
            selected: value == item,
            onSelected: (selected) => onChanged(selected ? item : null),
          ),
      ],
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
