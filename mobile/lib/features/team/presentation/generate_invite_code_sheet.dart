import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/data/invitations_repository.dart';
import '../../projects/domain/membership.dart';
import '../../stages/application/stages_controller.dart';
import '../domain/representative_rights_l10n.dart';

/// P2: бригадир/заказчик генерирует 6-значный код приглашения.
/// Bottom-sheet с тремя экранами:
/// 1. Роль (+ права для representative + этапы для foreman),
/// 2. Сгенерированный код с готовым сообщением для отправки.
Future<void> showGenerateInviteCodeSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
}) async {
  await showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    child: _Body(projectId: projectId),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.projectId});
  final String projectId;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  MembershipRole? _role;
  final Map<DomainAction, bool> _permissions = {};
  final Set<String> _selectedStageIds = {};
  bool _busy = false;
  String? _error;
  InviteCode? _code;

  Future<void> _generate() async {
    final role = _role;
    if (role == null) {
      setState(() => _error = 'Выберите роль приглашаемого.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(invitationsRepositoryProvider);
      Map<String, bool>? perms;
      if (role == MembershipRole.representative) {
        perms = {
          for (final entry in _permissions.entries.where((e) => e.value))
            entry.key.value: true,
        };
        // Если ничего не выбрано — представитель только наблюдает.
        // Это валидно: бекенд примет пустой объект.
      }
      List<String>? stageIds;
      if (role == MembershipRole.foreman && _selectedStageIds.isNotEmpty) {
        stageIds = _selectedStageIds.toList();
      }
      final code = await repo.generateCode(
        projectId: widget.projectId,
        role: role,
        permissions: perms,
        stageIds: stageIds,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _code = code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Не удалось создать код. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _code == null ? _Form(state: this) : _Result(state: this),
      ),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({required this.state});

  final _BodyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(invitableRolesProvider(state.widget.projectId));
    if (allowed.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.x16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheetHeader(
              title: 'Недостаточно прав',
              subtitle: 'Только заказчик и бригадир (с правом приглашать) '
                  'могут создавать коды приглашения.',
            ),
          ],
        ),
      );
    }
    if (state._role == null || !allowed.contains(state._role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!state.mounted) return;
        // ignore: invalid_use_of_protected_member
        state.setState(() => state._role = allowed.first);
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHeader(
          title: 'Пригласить в проект',
          subtitle: 'Сгенерируйте 6-значный код. Получатель введёт его '
              'в своём приложении и сразу увидит проект.',
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RoleSelector(
                  allowed: allowed,
                  value: state._role,
                  onChanged: (r) {
                    // ignore: invalid_use_of_protected_member
                    state.setState(() {
                      state._role = r;
                      // Сбросим частные настройки при смене роли.
                      state._permissions.clear();
                      state._selectedStageIds.clear();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.x14),
                _RoleHint(role: state._role),
                if (state._role == MembershipRole.representative) ...[
                  const SizedBox(height: AppSpacing.x16),
                  const _SectionLabel('Какие действия делегируем?'),
                  for (final groupEntry in kRightsGrouped.entries) ...[
                    const SizedBox(height: AppSpacing.x8),
                    Text(groupEntry.key, style: AppTextStyles.micro),
                    for (final action in groupEntry.value)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: state._permissions[action] ?? false,
                        title: Text(
                          kRightsRu[action]?.title ?? action.value,
                          style: AppTextStyles.body,
                        ),
                        subtitle: kRightsRu[action] != null
                            ? Text(
                                kRightsRu[action]!.description,
                                style: AppTextStyles.micro
                                    .copyWith(color: AppColors.n400),
                              )
                            : null,
                        activeColor: AppColors.brand,
                        onChanged: (v) {
                          // ignore: invalid_use_of_protected_member
                          state.setState(
                            () => state._permissions[action] = v ?? false,
                          );
                        },
                      ),
                  ],
                ],
                if (state._role == MembershipRole.foreman) ...[
                  const SizedBox(height: AppSpacing.x16),
                  const _SectionLabel('Каким этапам открыть доступ?'),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Если ничего не выбрать — бригадир получит доступ '
                    'ко всем этапам проекта.',
                    style: AppTextStyles.micro
                        .copyWith(color: AppColors.n400),
                  ),
                  const SizedBox(height: AppSpacing.x10),
                  _StagePicker(
                    projectId: state.widget.projectId,
                    selected: state._selectedStageIds,
                    onToggle: (id) {
                      // ignore: invalid_use_of_protected_member
                      state.setState(() {
                        if (state._selectedStageIds.contains(id)) {
                          state._selectedStageIds.remove(id);
                        } else {
                          state._selectedStageIds.add(id);
                        }
                      });
                    },
                  ),
                ],
                if (state._error != null) ...[
                  const SizedBox(height: AppSpacing.x12),
                  AppInlineError(message: state._error!),
                ],
                const SizedBox(height: AppSpacing.x16),
              ],
            ),
          ),
        ),
        AppButton(
          label: 'Создать код',
          isLoading: state._busy,
          onPressed: state._generate,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.caption);
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.allowed,
    required this.value,
    required this.onChanged,
  });

  final List<MembershipRole> allowed;
  final MembershipRole? value;
  final ValueChanged<MembershipRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Роль приглашаемого'),
        const SizedBox(height: AppSpacing.x10),
        for (final r in allowed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x8),
            child: _RoleCard(
              role: r,
              selected: value == r,
              onTap: () => onChanged(r),
            ),
          ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final MembershipRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
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
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brand
                      : AppColors.n100,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(
                  _iconFor(role),
                  size: 18,
                  color: selected ? AppColors.n0 : AppColors.n500,
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.displayName, style: AppTextStyles.subtitle),
                    const SizedBox(height: 2),
                    Text(
                      _shortDescriptionFor(role),
                      style: AppTextStyles.micro
                          .copyWith(color: AppColors.n400),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.brand : AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(MembershipRole r) => switch (r) {
        MembershipRole.customer => Icons.person_outline,
        MembershipRole.representative =>
          Icons.assignment_ind_outlined,
        MembershipRole.foreman => Icons.engineering_outlined,
        MembershipRole.master => Icons.handyman_outlined,
      };

  static String _shortDescriptionFor(MembershipRole r) => switch (r) {
        MembershipRole.customer =>
          'Владелец проекта (один на проект).',
        MembershipRole.representative =>
          'Действует от имени заказчика.',
        MembershipRole.foreman =>
          'Ведёт работы и приглашает мастеров.',
        MembershipRole.master =>
          'Выполняет шаги: фото, отметки, замечания.',
      };
}

class _RoleHint extends StatelessWidget {
  const _RoleHint({required this.role});

  final MembershipRole? role;

  @override
  Widget build(BuildContext context) {
    if (role == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.n500,
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              _hintFor(role!),
              style:
                  AppTextStyles.micro.copyWith(color: AppColors.n500),
            ),
          ),
        ],
      ),
    );
  }

  static String _hintFor(MembershipRole r) => switch (r) {
        MembershipRole.customer =>
          'Заказчик добавляется только при создании проекта.',
        MembershipRole.representative =>
          'Ниже выберите, какие действия может делать представитель — '
              'согласовывать, видеть бюджет, приглашать.',
        MembershipRole.foreman =>
          'По умолчанию бригадир видит весь проект. '
              'Можно ограничить отдельными этапами.',
        MembershipRole.master =>
          'Мастер увидит проект и сможет вести шаги после входа.',
      };
}

class _StagePicker extends ConsumerWidget {
  const _StagePicker({
    required this.projectId,
    required this.selected,
    required this.onToggle,
  });

  final String projectId;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stagesControllerProvider(projectId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n100,
          borderRadius: AppRadius.card,
        ),
        child: Text(
          'Не удалось загрузить этапы. Доступ откроем ко всем — '
          'это безопасный дефолт.',
          style: AppTextStyles.micro.copyWith(color: AppColors.n500),
        ),
      ),
      data: (stages) {
        if (stages.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: AppRadius.card,
            ),
            child: Text(
              'В проекте пока нет этапов — бригадир получит доступ '
              'ко всему проекту автоматически.',
              style: AppTextStyles.micro.copyWith(color: AppColors.n500),
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in stages)
              FilterChip(
                label: Text(s.title),
                selected: selected.contains(s.id),
                onSelected: (_) => onToggle(s.id),
                selectedColor: AppColors.brandLight,
                checkmarkColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(
                    color: selected.contains(s.id)
                        ? AppColors.brand
                        : AppColors.n200,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.state});

  final _BodyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = state._code!;
    final formatted = code.token.replaceAllMapped(
      RegExp(r'(\d{3})(\d{3})'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    final projectAsync =
        ref.watch(projectControllerProvider(state.widget.projectId));
    final projectTitle = projectAsync.maybeWhen(
      data: (p) => p.title,
      orElse: () => 'проект',
    );
    final shareMessage = _composeShareMessage(
      projectTitle: projectTitle,
      code: code.token,
      role: code.role,
      expiresAt: code.expiresAt,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBottomSheetHeader(
          title: 'Код готов',
          subtitle: 'Передайте его получателю в любой мессенджер.',
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
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
                        'Роль: ${code.role.displayName}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.brandDark),
                      ),
                      Text(
                        'Действителен до ${_formatDate(code.expiresAt)}',
                        style: AppTextStyles.micro
                            .copyWith(color: AppColors.brandDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
                _ShareMessagePreview(message: shareMessage),
                if (code.stageIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x12),
                  _ScopeNote(
                    text: 'Доступ только к выбранным этапам '
                        '(${code.stageIds.length}).',
                  ),
                ],
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
                onPressed: () => _copy(context, code.token, 'Код'),
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: AppButton(
                label: 'Копировать текст',
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    _copy(context, shareMessage, 'Сообщение'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Готово',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
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
    final pretty = code.replaceAllMapped(
      RegExp(r'(\d{3})(\d{3})'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
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

class _ScopeNote extends StatelessWidget {
  const _ScopeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x10),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.yellowDot,
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.yellowText),
            ),
          ),
        ],
      ),
    );
  }
}
