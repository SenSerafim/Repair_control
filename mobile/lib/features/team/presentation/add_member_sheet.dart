import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/phone_formatter.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import '../data/team_repository.dart';
import '../domain/invitation.dart';

/// s-add-member / s-member-found / s-member-not-found — единый flow в
/// bottom-sheet'е. После создания приглашения для незарегистрированного
/// пользователя показывает 6-значный код, который владелец проекта
/// отправляет получателю самостоятельно (любой канал — sms / мессенджер).
Future<void> showAddMemberSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
}) async {
  await showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
  Invitation? _createdInvitation;
  String? _error;
  MembershipRole? _role;

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
      _createdInvitation = null;
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
    final role = _role;
    if (result?.user == null || role == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(teamControllerProvider(widget.projectId).notifier)
        .addMember(userId: result!.user!.id, role: role);
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
    final role = _role;
    if (result == null || role == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final invitation =
          await ref.read(teamRepositoryProvider).invite(
                projectId: widget.projectId,
                phone: result.phone,
                role: role,
              );
      if (!mounted) return;
      // Обновим список приглашений в TeamController.
      ref.invalidate(teamControllerProvider(widget.projectId));
      setState(() {
        _submitting = false;
        _createdInvitation = invitation;
      });
    } on TeamException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.failure.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: _createdInvitation != null
            ? _InviteCodeView(
                invitation: _createdInvitation!,
                projectId: widget.projectId,
                phone: _result?.phone ?? _createdInvitation!.phone,
                onClose: () => Navigator.of(context).pop(),
              )
            : SingleChildScrollView(child: _form()),
      ),
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Добавить участника',
          subtitle:
              'Введите номер телефона. Если он зарегистрирован — добавим '
              'в команду сразу. Если нет — выдадим код, который вы '
              'отправите получателю любым удобным способом.',
        ),
        if (_error != null) ...[
          AppInlineError(message: _error!),
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide:
                  const BorderSide(color: AppColors.n200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide:
                  const BorderSide(color: AppColors.brand, width: 1.5),
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
          Consumer(
            builder: (context, ref, _) {
              final allowed =
                  ref.watch(invitableRolesProvider(widget.projectId));
              if (allowed.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: AppColors.yellowBg,
                    borderRadius: AppRadius.card,
                  ),
                  child: Text(
                    'У вашей роли нет права приглашать в этот проект.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.yellowText),
                  ),
                );
              }
              if (_role == null || !allowed.contains(_role)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _role = allowed.first);
                });
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Роль в проекте',
                      style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.x6),
                  _RolePicker(
                    roles: allowed,
                    value: _role,
                    onChanged: (r) => setState(() => _role = r),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    _hintFor(_role),
                    style: AppTextStyles.micro
                        .copyWith(color: AppColors.n400),
                  ),
                  const SizedBox(height: AppSpacing.x16),
                  if (_result!.user != null)
                    AppButton(
                      label: 'Добавить в команду',
                      isLoading: _submitting,
                      onPressed: _role == null ? null : _addExistingUser,
                    )
                  else
                    AppButton(
                      label: 'Создать код приглашения',
                      isLoading: _submitting,
                      onPressed: _role == null ? null : _inviteByPhone,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x16),
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
          const Icon(Icons.person_search_outlined,
              color: AppColors.yellowDot),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              'Номер ${result.phone} не зарегистрирован. '
              'Создадим код приглашения — отправите его получателю '
              'любым способом, и он зайдёт в проект.',
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
  const _RolePicker({
    required this.roles,
    required this.value,
    required this.onChanged,
  });

  final List<MembershipRole> roles;
  final MembershipRole? value;
  final ValueChanged<MembershipRole> onChanged;

  @override
  Widget build(BuildContext context) {
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

String _hintFor(MembershipRole? r) {
  switch (r) {
    case MembershipRole.customer:
      return 'Заказчик — владелец проекта (один на проект).';
    case MembershipRole.representative:
      return 'Представитель действует от имени заказчика — '
          'почти все полномочия. Конкретные права можно сузить позже.';
    case MembershipRole.foreman:
      return 'Бригадир ведёт работы по этапам и приглашает мастеров.';
    case MembershipRole.master:
      return 'Мастер выполняет шаги, прикладывает фото и закрывает их.';
    case null:
      return 'Выберите роль участника.';
  }
}

/// Экран успеха: показывает 6-значный код приглашения с готовым сообщением
/// для отправки. Аналог UX из generate_invite_code_sheet, но в контексте
/// «не нашли по телефону».
class _InviteCodeView extends ConsumerWidget {
  const _InviteCodeView({
    required this.invitation,
    required this.projectId,
    required this.phone,
    required this.onClose,
  });

  final Invitation invitation;
  final String projectId;
  final String phone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = invitation.token ?? '';
    final formatted = token.length == 6
        ? token.replaceAllMapped(
            RegExp(r'(\d{3})(\d{3})'),
            (m) => '${m.group(1)} ${m.group(2)}',
          )
        : token;
    final projectAsync = ref.watch(projectControllerProvider(projectId));
    final projectTitle = projectAsync.maybeWhen(
      data: (p) => p.title,
      orElse: () => 'проект',
    );
    final shareMessage = _composeShareMessage(
      projectTitle: projectTitle,
      code: token,
      role: invitation.role,
      expiresAt: invitation.expiresAt,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHeader(
          title: 'Код готов',
          subtitle:
              'Отправьте код получателю любым способом — sms, мессенджер.',
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        formatted,
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
                        'Кому: $phone',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.brandDark),
                      ),
                      Text(
                        'Роль: ${invitation.role.displayName}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.brandDark),
                      ),
                      Text(
                        'Действителен до ${_formatDate(invitation.expiresAt)}',
                        style: AppTextStyles.micro
                            .copyWith(color: AppColors.brandDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
                _ShareMessagePreview(message: shareMessage),
                const SizedBox(height: AppSpacing.x16),
              ],
            ),
          ),
        ),
        AppButton(
          label: 'Отправить через…',
          icon: Icons.send_rounded,
          onPressed: () => _share(shareMessage),
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
                onPressed: () => _copy(context, shareMessage, 'Сообщение'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Готово',
          variant: AppButtonVariant.ghost,
          onPressed: onClose,
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

  static Future<void> _share(String text) async {
    await Share.share(text, subject: 'Приглашение в проект');
  }

  static String _composeShareMessage({
    required String projectTitle,
    required String code,
    required MembershipRole role,
    required DateTime expiresAt,
  }) {
    final df = DateFormat("d MMMM 'до' HH:mm", 'ru');
    final until = df.format(expiresAt.toLocal());
    final pretty = code.length == 6
        ? code.replaceAllMapped(
            RegExp(r'(\d{3})(\d{3})'),
            (m) => '${m.group(1)} ${m.group(2)}',
          )
        : code;
    final greeting =
        'Здравствуйте! Приглашаю вас в проект «$projectTitle» '
        'в Repair Control как ${role.displayName.toLowerCase()}.';
    const howTo = 'Откройте приложение, нажмите «Присоединиться по коду» '
        'и введите этот код.';
    return [
      greeting,
      '',
      'Код для входа: $pretty',
      'Действителен до $until.',
      '',
      howTo,
    ].join('\n');
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${local.year} $hh:$mi';
  }
}

class _ShareMessagePreview extends StatelessWidget {
  const _ShareMessagePreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Icon(
                Icons.send_outlined,
                size: 16,
                color: AppColors.brand,
              ),
              const SizedBox(width: AppSpacing.x6),
              Text(
                'Готовое сообщение',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.brand),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(message, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
