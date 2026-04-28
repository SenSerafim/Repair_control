import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';

/// s-delete-confirm — bottom-sheet удаления аккаунта.
///
/// Требует подтверждения вводом «УДАЛИТЬ» (case-sensitive). После DELETE /me
/// делаем logout (очистит токены, секьюр-стор, drift-кеш) и переходим на
/// `/welcome`.
Future<void> showDeleteAccountSheet(BuildContext context, WidgetRef ref) async {
  await showAppBottomSheet<void>(
    context: context,
    child: const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState
    extends ConsumerState<_DeleteAccountSheet> {
  static const _confirmWord = 'УДАЛИТЬ';

  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _ctrl.text == _confirmWord && !_busy;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      if (!mounted) return;
      // Sheet закрываем перед logout — иначе onDispose может race с
      // GoRouter.redirect → /welcome.
      Navigator.of(context).pop();
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      context.go(AppRoutes.welcome);
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.failure.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.redBg,
            borderRadius: BorderRadius.circular(AppRadius.r20),
          ),
          child: Icon(
            PhosphorIconsFill.trash,
            color: AppColors.redDot,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        const Text(
          'Удалить аккаунт?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.n800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.x16),
          child: Text(
            'Все ваши проекты, данные и история будут удалены '
            'безвозвратно. Это действие нельзя отменить.',
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
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Введите УДАЛИТЬ для подтверждения',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.n500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.redBg,
            border: Border.all(color: AppColors.redDot, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.redText,
              letterSpacing: 2,
            ),
            decoration: const InputDecoration(
              hintText: _confirmWord,
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0x66DC2626),
                letterSpacing: 2,
              ),
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.x10),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.redText,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x20),
        AppButton(
          label: 'Подтвердить удаление',
          variant: AppButtonVariant.destructive,
          isLoading: _busy,
          onPressed: _canSubmit ? _delete : null,
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
