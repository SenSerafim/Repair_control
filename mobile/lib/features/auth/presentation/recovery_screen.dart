import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/recovery_controller.dart';
import '../domain/auth_failure.dart';
import 'phone_formatter.dart';

/// s-recovery / s-recovery-phone / s-recovery-newpass — 3 шага FSM.
class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recoveryControllerProvider);

    return AppScaffold(
      showBack: true,
      title: 'Восстановление доступа',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: switch (state.step) {
        RecoveryStep.enterPhone => const _PhoneStep(),
        RecoveryStep.enterCode => const _CodeStep(),
        RecoveryStep.enterNewPassword => const _NewPasswordStep(),
        RecoveryStep.done => const _DoneStep(),
      },
    );
  }
}

class _PhoneStep extends ConsumerStatefulWidget {
  const _PhoneStep();

  @override
  ConsumerState<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends ConsumerState<_PhoneStep> {
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(recoveryControllerProvider);
    final ctrl = ref.read(recoveryControllerProvider.notifier);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x16),
          const Text(
            'Введите телефон — пришлём 6-значный код.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x16),
          if (s.lastFailure != null) ...[
            _Banner(failure: s.lastFailure!),
            const SizedBox(height: AppSpacing.x12),
          ],
          const Text('Телефон', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Введите телефон';
              if (!isValidPhoneE164(v)) return 'Введите корректный номер';
              return null;
            },
            decoration: _dec('+7 000 000 00 00'),
          ),
          const SizedBox(height: AppSpacing.x24),
          AppButton(
            label: 'Получить код',
            isLoading: s.isSubmitting,
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              await ctrl.sendCode(phoneToE164(_phone.text));
            },
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends ConsumerStatefulWidget {
  const _CodeStep();

  @override
  ConsumerState<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends ConsumerState<_CodeStep> {
  Timer? _ticker;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(recoveryControllerProvider);
    final ctrl = ref.read(recoveryControllerProvider.notifier);
    final resendIn = s.resendIn;
    final canResend = resendIn == Duration.zero;
    final failure = s.lastFailure;

    String? errorText;
    if (failure == AuthFailure.recoveryInvalidCode) {
      errorText = 'Неверный код';
    } else if (failure == AuthFailure.recoveryExpired) {
      errorText = 'Код истёк. Запросите новый.';
    } else if (failure == AuthFailure.blocked) {
      errorText = 'Слишком много попыток.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.x16),
        Text(
          'Мы отправили 6-значный код на ${s.phone}.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x24),
        PinInput(
          length: 6,
          errorText: errorText,
          onChanged: (v) => _code = v,
          onCompleted: ctrl.verifyCode,
        ),
        const SizedBox(height: AppSpacing.x24),
        AppButton(
          label: 'Подтвердить код',
          isLoading: s.isSubmitting,
          onPressed: _code.length == 6 ? () => ctrl.verifyCode(_code) : null,
        ),
        const SizedBox(height: AppSpacing.x12),
        TextButton(
          onPressed: canResend && !s.isSubmitting
              ? () => ctrl.sendCode(s.phone)
              : null,
          child: Text(
            canResend
                ? 'Отправить код ещё раз'
                : 'Повторно через ${resendIn.inSeconds} с',
          ),
        ),
      ],
    );
  }
}

class _NewPasswordStep extends ConsumerStatefulWidget {
  const _NewPasswordStep();

  @override
  ConsumerState<_NewPasswordStep> createState() => _NewPasswordStepState();
}

class _NewPasswordStepState extends ConsumerState<_NewPasswordStep> {
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(recoveryControllerProvider);
    final ctrl = ref.read(recoveryControllerProvider.notifier);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x16),
          const Text(
            'Придумайте новый пароль — минимум 8 символов.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x16),
          if (s.lastFailure != null) ...[
            _Banner(failure: s.lastFailure!),
            const SizedBox(height: AppSpacing.x12),
          ],
          const Text('Новый пароль', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Введите пароль';
              if (v.length < 8) return 'Минимум 8 символов';
              return null;
            },
            decoration: _dec(
              'Минимум 8 символов',
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.n400,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x24),
          AppButton(
            label: 'Сохранить пароль',
            isLoading: s.isSubmitting,
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              await ctrl.resetPassword(_password.text);
            },
          ),
        ],
      ),
    );
  }
}

class _DoneStep extends ConsumerWidget {
  const _DoneStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(AppRadius.r24),
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.greenDark,
            size: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        const Center(
          child: Text('Пароль обновлён', style: AppTextStyles.h1),
        ),
        const SizedBox(height: AppSpacing.x8),
        const Center(
          child: Text(
            'Можно войти с новым паролем.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        const Spacer(flex: 3),
        AppButton(
          label: 'Перейти ко входу',
          onPressed: () {
            ref.read(recoveryControllerProvider.notifier).reset();
            context.go(AppRoutes.login);
          },
        ),
        const SizedBox(height: AppSpacing.x24),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.failure});

  final AuthFailure failure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.redDot, size: 20),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              failure.userMessage,
              style: AppTextStyles.body.copyWith(color: AppColors.redText),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
      filled: true,
      fillColor: AppColors.n0,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      suffixIcon: suffix,
      border: _border(AppColors.n200),
      enabledBorder: _border(AppColors.n200),
      focusedBorder: _border(AppColors.brand),
      errorBorder: _border(AppColors.redDot),
      focusedErrorBorder: _border(AppColors.redDot),
    );

OutlineInputBorder _border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      borderSide: BorderSide(color: c, width: 1.5),
    );
