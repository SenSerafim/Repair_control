import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../domain/auth_failure.dart';
import 'phone_formatter.dart';

/// s-login / s-login-error / s-login-loading / s-network-error — все 5
/// состояний собраны в одном экране и управляются через local state.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  AuthFailure? _failure;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Введите телефон';
    if (!isValidPhoneE164(v)) return 'Введите корректный номер';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Введите пароль';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final failure = await ref.read(authControllerProvider.notifier).login(
          phone: phoneToE164(_phone.text),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failure = failure;
    });

    if (failure == null && context.mounted) {
      AppToast.show(context, message: 'Добро пожаловать!',
          kind: AppToastKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneError = _failure == AuthFailure.invalidCredentials
        ? 'Неверный телефон или пароль'
        : null;

    return AppScaffold(
      showBack: true,
      title: 'Вход',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.x16),
            if (_failure != null) ...[
              _FailureBanner(failure: _failure!),
              const SizedBox(height: AppSpacing.x16),
            ],
            _LabeledField(
              label: 'Телефон',
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [PhoneInputFormatter()],
                validator: _validatePhone,
                decoration: _inputDecoration(
                  hint: '+7 000 000 00 00',
                  errorText: phoneError,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
            _LabeledField(
              label: 'Пароль',
              child: TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                validator: _validatePassword,
                decoration: _inputDecoration(
                  hint: 'Ваш пароль',
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
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.recovery),
                child: const Text('Забыли пароль?'),
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            AppButton(
              label: 'Войти',
              onPressed: _submit,
              isLoading: _loading,
            ),
            const SizedBox(height: AppSpacing.x24),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Нет аккаунта? ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.register),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Зарегистрироваться'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? errorText,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
      errorText: errorText,
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
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: BorderSide(color: c, width: 1.5),
      );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.x6),
        child,
      ],
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.failure});

  final AuthFailure failure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.redDot.withValues(alpha: 0.2)),
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
