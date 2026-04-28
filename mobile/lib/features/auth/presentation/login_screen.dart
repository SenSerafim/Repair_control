import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../domain/auth_failure.dart';
import 'phone_formatter.dart';

/// s-login + s-login-error + s-login-loading.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  AuthFailure? _failure;
  bool _obscure = true;
  int _remainingAttempts = 3;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _failure = AuthFailure.validation);
      return;
    }
    if (!isValidPhoneE164(_phone.text)) {
      setState(() => _failure = AuthFailure.validation);
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
    });
    final failure = await ref.read(authControllerProvider.notifier).login(
          phone: phoneToE164(_phone.text),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failure = failure;
      if (failure == AuthFailure.invalidCredentials) {
        _remainingAttempts = (_remainingAttempts - 1).clamp(0, 3);
      } else if (failure == null) {
        _remainingAttempts = 3;
      }
    });
    if (failure == null && mounted) {
      AppToast.show(
        context,
        message: 'Добро пожаловать!',
        kind: AppToastKind.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _failure == AuthFailure.invalidCredentials;
    final passwordError = hasError
        ? 'Неверный пароль. Осталось $_remainingAttempts ${_pluralize(_remainingAttempts)}.'
        : null;

    return AppScaffold(
      showBack: true,
      title: 'Вход',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: _loading
          ? const _LoadingSkeleton()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.x16),
                const Text(
                  'С возвращением',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                const Text(
                  'Введите номер телефона и пароль',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.n400,
                  ),
                ),
                const SizedBox(height: AppSpacing.x24),
                AppInput(
                  controller: _phone,
                  label: 'Номер телефона',
                  placeholder: '+7 (000) 000-00-00',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  prefixIcon: const _CountryPrefix(),
                ),
                const SizedBox(height: AppSpacing.x12),
                AppInput(
                  controller: _password,
                  label: 'Пароль',
                  placeholder: '••••••••',
                  obscureText: _obscure,
                  errorText: passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? PhosphorIconsRegular.eye
                          : PhosphorIconsRegular.eyeSlash,
                      size: 20,
                      color: hasError ? AppColors.redDot : AppColors.n400,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppSpacing.x12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.recovery),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Забыли пароль?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x16),
                AppButton(
                  label: hasError ? 'Повторить' : 'Войти',
                  onPressed: _submit,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x24),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Нет аккаунта? ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.n500,
                              ),
                            ),
                            TextSpan(
                              text: 'Зарегистрироваться',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

String _pluralize(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'попытка';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'попытки';
  return 'попыток';
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇷🇺', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text(
            '+7',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.n700,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 22, color: AppColors.n200),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeletonRow(width: 180, height: 22),
          SizedBox(height: AppSpacing.x12),
          AppSkeletonRow(width: 220, height: 14),
          SizedBox(height: AppSpacing.x32),
          AppSkeletonRow(height: 52),
          SizedBox(height: AppSpacing.x12),
          AppSkeletonRow(height: 52),
          SizedBox(height: AppSpacing.x32),
          AppSkeletonRow(height: 54),
          SizedBox(height: AppSpacing.x16),
          Center(
            child: Text(
              'Загрузка данных...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
