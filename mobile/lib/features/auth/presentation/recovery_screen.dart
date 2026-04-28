import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/recovery_controller.dart';
import '../domain/auth_failure.dart';
import 'phone_formatter.dart';

/// s-recovery-phone / s-recovery / s-recovery-newpass — 3-шаговый wizard со
/// `AppStepDots`, большой иконкой-кругом и описанием.
class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recoveryControllerProvider);

    return AppScaffold(
      showBack: true,
      title: 'Восстановление пароля',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x20),
          AppStepDots(total: 3, current: _stepIndex(state.step)),
          const SizedBox(height: AppSpacing.x32),
          Expanded(
            child: switch (state.step) {
              RecoveryStep.enterPhone => const _PhoneStep(),
              RecoveryStep.enterCode => const _CodeStep(),
              RecoveryStep.enterNewPassword => const _NewPasswordStep(),
              RecoveryStep.done => const _DoneStep(),
            },
          ),
        ],
      ),
    );
  }

  int _stepIndex(RecoveryStep step) => switch (step) {
        RecoveryStep.enterPhone => 0,
        RecoveryStep.enterCode => 1,
        RecoveryStep.enterNewPassword => 2,
        RecoveryStep.done => 2,
      };
}

class _StepHero extends StatelessWidget {
  const _StepHero({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBg = AppColors.brandLight,
    this.iconColor = AppColors.brand,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppRadius.r20),
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: AppSpacing.x16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.n800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.x8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.n400,
            height: 1.45,
          ),
        ),
      ],
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

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!isValidPhoneE164(_phone.text)) return;
    await ref
        .read(recoveryControllerProvider.notifier)
        .sendCode(phoneToE164(_phone.text));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(recoveryControllerProvider);
    final failure = s.lastFailure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHero(
          icon: PhosphorIconsFill.deviceMobile,
          title: 'Введите номер телефона',
          subtitle: 'Мы отправим SMS-код для восстановления доступа',
        ),
        const SizedBox(height: AppSpacing.x32),
        AppInput(
          controller: _phone,
          label: 'Номер телефона',
          placeholder: '+7 (000) 000-00-00',
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          errorText: failure?.userMessage,
        ),
        const Spacer(),
        AppButton(
          label: 'Отправить код',
          isLoading: s.isSubmitting,
          onPressed: _send,
        ),
        const SizedBox(height: AppSpacing.x24),
      ],
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

    final masked = _maskPhone(s.phone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHero(
          icon: PhosphorIconsFill.chatCircleText,
          title: 'Введите код из SMS',
          subtitle: 'Отправили на $masked',
        ),
        const SizedBox(height: AppSpacing.x32),
        PinInput(
          length: 6,
          errorText: errorText,
          onChanged: (v) => _code = v,
          onCompleted: ctrl.verifyCode,
        ),
        const SizedBox(height: AppSpacing.x16),
        Center(
          child: GestureDetector(
            onTap: canResend && !s.isSubmitting
                ? () => ctrl.sendCode(s.phone)
                : null,
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Не пришёл код? ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.n500,
                    ),
                  ),
                  TextSpan(
                    text: canResend
                        ? 'Отправить снова'
                        : 'Повторно через ${resendIn.inSeconds} с',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: canResend ? AppColors.brand : AppColors.n400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        AppButton(
          label: 'Подтвердить',
          isLoading: s.isSubmitting,
          onPressed: _code.length == 6 ? () => ctrl.verifyCode(_code) : null,
        ),
        const SizedBox(height: AppSpacing.x24),
      ],
    );
  }

  String _maskPhone(String e164) {
    if (e164.length < 7) return e164;
    final tail = e164.substring(e164.length - 2);
    return '+7 (XXX) XXX-XX-$tail';
  }
}

class _NewPasswordStep extends ConsumerStatefulWidget {
  const _NewPasswordStep();

  @override
  ConsumerState<_NewPasswordStep> createState() => _NewPasswordStepState();
}

class _NewPasswordStepState extends ConsumerState<_NewPasswordStep> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;
  String? _localError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 8) {
      setState(() => _localError = 'Минимум 8 символов');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _localError = 'Пароли не совпадают');
      return;
    }
    setState(() => _localError = null);
    await ref
        .read(recoveryControllerProvider.notifier)
        .resetPassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(recoveryControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHero(
          icon: PhosphorIconsFill.lockOpen,
          title: 'Новый пароль',
          subtitle: 'Придумайте новый пароль для вашего аккаунта',
          iconBg: Color(0xFFDEF7EC),
          iconColor: AppColors.greenDark,
        ),
        const SizedBox(height: AppSpacing.x32),
        AppInput(
          controller: _password,
          label: 'Новый пароль',
          placeholder: 'Минимум 8 символов',
          obscureText: _obscure,
          errorText: _localError,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? PhosphorIconsRegular.eye
                  : PhosphorIconsRegular.eyeSlash,
              size: 20,
              color: AppColors.n400,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        AppInput(
          controller: _confirm,
          label: 'Повторите пароль',
          placeholder: 'Повторите пароль',
          obscureText: _obscure2,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure2
                  ? PhosphorIconsRegular.eye
                  : PhosphorIconsRegular.eyeSlash,
              size: 20,
              color: AppColors.n400,
            ),
            onPressed: () => setState(() => _obscure2 = !_obscure2),
          ),
        ),
        const Spacer(),
        AppButton(
          label: 'Сохранить пароль',
          variant: AppButtonVariant.success,
          icon: PhosphorIconsBold.check,
          isLoading: s.isSubmitting,
          onPressed: _save,
        ),
        const SizedBox(height: AppSpacing.x24),
      ],
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
        Center(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.successHero,
              borderRadius: BorderRadius.circular(AppRadius.r24),
              boxShadow: AppShadows.shGreen,
            ),
            child: Icon(
              PhosphorIconsBold.check,
              color: AppColors.n0,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        const Center(
          child: Text(
            'Пароль обновлён',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x8),
        const Center(
          child: Text(
            'Можно войти с новым паролем.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.n400,
            ),
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
