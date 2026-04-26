import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/domain_actions.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/data/invitations_repository.dart';
import '../../projects/domain/membership.dart';
import '../domain/representative_rights_l10n.dart';

/// P2: бригадир/заказчик генерирует 6-значный код приглашения.
/// Bottom-sheet: выбор роли → (для representative — права) → создание кода → шаринг.
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
  MembershipRole _role = MembershipRole.master;
  final Map<DomainAction, bool> _permissions = {};
  bool _busy = false;
  String? _error;
  InviteCode? _code;

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(invitationsRepositoryProvider);
      // Для representative собираем булевы permissions.
      Map<String, bool>? perms;
      if (_role == MembershipRole.representative) {
        perms = {
          for (final entry in _permissions.entries.where((e) => e.value))
            entry.key.value: true,
        };
      }
      final code = await repo.generateCode(
        projectId: widget.projectId,
        role: _role,
        permissions: perms,
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _code == null ? _form() : _result(_code!),
      ),
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Сгенерировать код',
          subtitle: 'Поделитесь кодом — получатель введёт его в своём приложении.',
        ),
        const Text('Роль', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.x6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in const [
              MembershipRole.foreman,
              MembershipRole.master,
              MembershipRole.representative,
            ])
              ChoiceChip(
                label: Text(r.displayName),
                selected: _role == r,
                onSelected: (_) => setState(() => _role = r),
              ),
          ],
        ),
        if (_role == MembershipRole.representative) ...[
          const SizedBox(height: AppSpacing.x14),
          const Text('Права представителя', style: AppTextStyles.caption),
          for (final groupEntry in kRightsGrouped.entries) ...[
            const SizedBox(height: AppSpacing.x8),
            Text(groupEntry.key, style: AppTextStyles.micro),
            for (final action in groupEntry.value)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _permissions[action] ?? false,
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
                onChanged: (v) => setState(
                  () => _permissions[action] = v ?? false,
                ),
              ),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.x12),
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
        ],
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Создать код',
          isLoading: _busy,
          onPressed: _generate,
        ),
      ],
    );
  }

  Widget _result(InviteCode code) {
    final formatted = code.token.replaceAllMapped(
      RegExp(r'(\d{3})(\d{3})'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Код приглашения',
          subtitle: 'Передайте получателю любым способом — sms, мессенджер.',
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: AppRadius.card,
          ),
          child: Center(
            child: Text(
              formatted,
              style: const TextStyle(
                fontSize: 40,
                letterSpacing: 6,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Действителен до ${_formatDate(code.expiresAt)}',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.x16),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Скопировать',
                variant: AppButtonVariant.ghost,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code.token));
                  if (!mounted) return;
                  AppToast.show(
                    context,
                    message: 'Код скопирован',
                    kind: AppToastKind.success,
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: AppButton(
                label: 'Закрыть',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year} $hh:$mi';
  }
}
