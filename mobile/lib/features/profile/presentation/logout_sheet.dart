import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';

/// Bottom-sheet подтверждения выхода из аккаунта.
///
/// После «Да, выйти» — `auth_controller.logout()` сбрасывает токены
/// и `GoRouter.redirect` уносит на `/welcome`. Sheet закрываем до
/// logout(), чтобы избежать race с unmount ProfileScreen.
Future<void> showLogoutSheet(BuildContext context, WidgetRef ref) async {
  await showAppBottomSheet<void>(
    context: context,
    child: _LogoutSheet(rootRef: ref),
  );
}

class _LogoutSheet extends StatefulWidget {
  const _LogoutSheet({required this.rootRef});

  final WidgetRef rootRef;

  @override
  State<_LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<_LogoutSheet> {
  bool _busy = false;

  Future<void> _doLogout() async {
    if (_busy) return;
    setState(() => _busy = true);
    Navigator.of(context).pop();
    await widget.rootRef.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: AppSpacing.x4),
          decoration: BoxDecoration(
            color: AppColors.yellowBg,
            borderRadius: BorderRadius.circular(AppRadius.r20),
          ),
          child: Icon(
            PhosphorIconsFill.signOut,
            color: AppColors.yellowText,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        const Center(
          child: Text(
            'Выйти из аккаунта?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.x16),
          child: Text(
            'Потребуется ввести телефон и пароль, чтобы войти снова. '
            'Данные аккаунта останутся на сервере.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.n500,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x20),
        AppButton(
          label: 'Да, выйти',
          variant: AppButtonVariant.destructive,
          icon: PhosphorIconsRegular.signOut,
          isLoading: _busy,
          onPressed: _busy ? null : _doLogout,
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
