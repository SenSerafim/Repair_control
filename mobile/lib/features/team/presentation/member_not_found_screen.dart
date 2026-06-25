import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../profile/application/profile_controller.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/data/invitations_repository.dart';
import '../../projects/domain/membership.dart';

/// s-member-not-found — пользователь по телефону не найден.
///
/// 2026-05 рефактор: вместо фейкового invite-кода `abc123` и кнопки «SMS»
/// (которая требовала бы SMS-провайдера) — единый flow:
///   1. role picker через `invitableRolesProvider`,
///   2. реальный 6-значный код через `POST /invitations/generate-code`,
///   3. готовое сообщение с кодом → share-sheet / копирование.
/// Получатель вводит код в приложении («Присоединиться по коду») и попадает
/// в проект с нужной ролью.
class MemberNotFoundScreen extends ConsumerStatefulWidget {
  const MemberNotFoundScreen({
    required this.projectId,
    required this.phone,
    super.key,
  });

  final String projectId;
  final String phone;

  @override
  ConsumerState<MemberNotFoundScreen> createState() =>
      _MemberNotFoundScreenState();
}

class _MemberNotFoundScreenState extends ConsumerState<MemberNotFoundScreen> {
  MembershipRole? _role;
  String? _specialization;
  bool _busy = false;
  InviteCode? _code;
  String? _error;

  Future<void> _generate() async {
    final role = _role;
    if (role == null) {
      setState(() => _error = 'Выберите роль.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref
          .read(invitationsRepositoryProvider)
          .generateCode(
            projectId: widget.projectId,
            role: role,
            specialization: role == MembershipRole.master
                ? _specialization
                : null,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _code = code;
      });
    } on InvitationsException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.failure.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(invitableRolesProvider(widget.projectId));
    if (_role == null && allowed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _role = allowed.first);
      });
    }
    return AppScaffold(
      showBack: true,
      title: 'Пользователь не найден',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: _code == null
          ? _buildForm(context, allowed)
          : _buildCodeResult(context, _code!),
    );
  }

  Widget _buildForm(BuildContext context, List<MembershipRole> allowed) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellowBg,
              borderRadius: BorderRadius.circular(AppRadius.r20),
            ),
            child: Icon(
              PhosphorIconsRegular.magnifyingGlassMinus,
              size: 32,
              color: AppColors.yellowText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        Center(
          child: Text(
            'Номер ${_formatPhone(widget.phone)} ещё не в приложении',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: const Text(
              'Сгенерируйте 6-значный код приглашения и отправьте его '
              'получателю любым удобным способом — sms, мессенджер. '
              'Он введёт код в приложении и попадёт в проект.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n500,
                height: 1.55,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x24),
        if (allowed.isEmpty)
          const _NoRightsCard()
        else ...[
          const Text(
            'РОЛЬ ПРИГЛАШАЕМОГО',
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
                _error = null;
              }),
            ),
            const SizedBox(height: AppSpacing.x8),
          ],
          if (_role == MembershipRole.master) ...[
            const SizedBox(height: AppSpacing.x8),
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
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.x8),
            AppInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.x20),
          AppButton(
            label: 'Создать код приглашения',
            icon: PhosphorIconsFill.paperPlaneTilt,
            isLoading: _busy,
            onPressed: _role == null ? null : _generate,
          ),
          const SizedBox(height: AppSpacing.x10),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Попробовать другой номер',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCodeResult(BuildContext context, InviteCode code) {
    final projectAsync = ref.watch(projectControllerProvider(widget.projectId));
    final projectTitle = projectAsync.maybeWhen(
      data: (p) => p.title,
      orElse: () => 'проект',
    );
    final inviter =
        ref.watch(profileControllerProvider).valueOrNull?.firstName ?? '';
    final token = code.token;
    final pretty = token.length == 6
        ? token.replaceAllMapped(
            RegExp(r'(\d{3})(\d{3})'),
            (m) => '${m.group(1)} ${m.group(2)}',
          )
        : token;
    final df = DateFormat("d MMMM 'до' HH:mm", 'ru');
    final until = df.format(code.expiresAt.toLocal());
    final greeting = inviter.isEmpty
        ? 'Здравствуйте! Приглашаю вас в проект «$projectTitle» '
              'в приложении «Контроль ремонта» как '
              '${code.role.displayName.toLowerCase()}.'
        : 'Здравствуйте! $inviter приглашает вас в проект «$projectTitle» '
              'в приложении «Контроль ремонта» как '
              '${code.role.displayName.toLowerCase()}.';
    final message = <String>[
      greeting,
      '',
      'Код для входа: $pretty',
      'Действителен до $until.',
      '',
      'Откройте приложение, нажмите «Присоединиться по коду» '
          'и введите этот код.',
    ].join('\n');

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(AppRadius.r20),
            ),
            child: Icon(
              PhosphorIconsFill.checkCircle,
              size: 36,
              color: AppColors.greenDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        const Center(
          child: Text(
            'Код приглашения создан',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x20),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x20,
          ),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: AppRadius.card,
          ),
          child: Column(
            children: [
              Text(
                pretty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                'Кому: ${_formatPhone(widget.phone)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
              Text(
                'Роль: ${code.role.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
              Text(
                'Действителен до $until',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n100,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.n200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.paperPlaneTilt,
                    size: 16,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: AppSpacing.x6),
                  const Text(
                    'Готовое сообщение',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.n700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Отправить через…',
          icon: PhosphorIconsFill.paperPlaneTilt,
          onPressed: () =>
              Share.share(message, subject: 'Приглашение в проект'),
        ),
        const SizedBox(height: AppSpacing.x8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Копировать код',
                variant: AppButtonVariant.secondary,
                onPressed: () => _copy(context, token, 'Код'),
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: AppButton(
                label: 'Копировать текст',
                variant: AppButtonVariant.secondary,
                onPressed: () => _copy(context, message, 'Сообщение'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Готово',
          variant: AppButtonVariant.ghost,
          onPressed: () =>
              context.go(AppRoutes.projectTeamWith(widget.projectId)),
        ),
      ],
    );
  }

  static Future<void> _copy(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: '$label скопирован',
      kind: AppToastKind.success,
    );
  }

  static String _formatPhone(String e164) {
    if (!e164.startsWith('+')) return e164;
    final digits = e164.substring(1).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || !digits.startsWith('7')) return e164;
    return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-'
        '${digits.substring(7, 9)}-${digits.substring(9, 11)}';
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
