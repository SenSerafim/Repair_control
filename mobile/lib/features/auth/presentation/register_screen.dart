import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../domain/auth_failure.dart';
import 'phone_formatter.dart';
import 'role_picker.dart';

/// s-reg — регистрация: телефон, имя, фамилия, пароль, роль.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();

  SystemRole? _role;
  bool _loading = false;
  AuthFailure? _failure;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final role = _role;
    if (role == null) {
      setState(() => _failure = AuthFailure.validation);
      return;
    }

    setState(() => _loading = true);
    final failure = await ref.read(authControllerProvider.notifier).register(
          phone: phoneToE164(_phone.text),
          password: _password.text,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          role: role,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Регистрация',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
          children: [
            if (_failure != null) ...[
              _InlineError(failure: _failure!),
              const SizedBox(height: AppSpacing.x16),
            ],
            const _Label('Телефон'),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [PhoneInputFormatter()],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Введите телефон';
                if (!isValidPhoneE164(v)) return 'Введите корректный номер';
                return null;
              },
              decoration: _dec('+7 000 000 00 00'),
            ),
            const SizedBox(height: AppSpacing.x12),
            const _Label('Имя'),
            TextFormField(
              controller: _firstName,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введите имя'
                  : null,
              decoration: _dec('Как вас зовут?'),
            ),
            const SizedBox(height: AppSpacing.x12),
            const _Label('Фамилия'),
            TextFormField(
              controller: _lastName,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введите фамилию'
                  : null,
              decoration: _dec('Ваша фамилия'),
            ),
            const SizedBox(height: AppSpacing.x12),
            const _Label('Пароль'),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Придумайте пароль';
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
            const SizedBox(height: AppSpacing.x20),
            const Text('Кто вы в проекте?', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.x12),
            for (final r in SystemRole.registerable) ...[
              RoleCard(
                role: r,
                selected: _role == r,
                onTap: () => setState(() => _role = r),
              ),
              const SizedBox(height: AppSpacing.x10),
            ],
            const SizedBox(height: AppSpacing.x12),
            AppButton(
              label: 'Создать аккаунт',
              onPressed: _submit,
              isLoading: _loading,
            ),
            const SizedBox(height: AppSpacing.x16),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('У меня уже есть аккаунт'),
              ),
            ),
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
    );
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
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x6),
      child: Text(text, style: AppTextStyles.caption),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.failure});

  final AuthFailure failure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
      ),
      child: Text(
        failure.userMessage,
        style: AppTextStyles.body.copyWith(color: AppColors.redText),
      ),
    );
  }
}
