import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../domain/auth_failure.dart';
import 'phone_formatter.dart';

/// s-reg — регистрация: имя/фамилия, телефон, пароль + 3-карточный role-grid.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();

  AppRoleKind _role = AppRoleKind.customer;
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
    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        !isValidPhoneE164(_phone.text) ||
        _password.text.length < 8) {
      setState(() => _failure = AuthFailure.validation);
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
    });
    final failure = await ref.read(authControllerProvider.notifier).register(
          phone: phoneToE164(_phone.text),
          password: _password.text,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          role: _role.systemRole,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
        children: [
          if (_failure != null) ...[
            _ErrorBanner(message: _failure!.userMessage),
            const SizedBox(height: AppSpacing.x16),
          ],
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _firstName,
                  label: 'Имя',
                  placeholder: 'Константин',
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: AppInput(
                  controller: _lastName,
                  label: 'Фамилия',
                  placeholder: 'Иванов',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: _phone,
            label: 'Номер телефона',
            placeholder: '+7 (000) 000-00-00',
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: _password,
            label: 'Пароль',
            placeholder: 'Минимум 8 символов',
            obscureText: _obscure,
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
          const SizedBox(height: AppSpacing.x20),
          const Text(
            'Выбор роли',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.n500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          // Сетка 2×2 с 4 ролями: Заказчик / Представитель / Бригадир / Мастер.
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.x8,
            mainAxisSpacing: AppSpacing.x8,
            childAspectRatio: 1.45,
            children: [
              for (final kind in AppRoleKind.values)
                AppRoleCard.kind(
                  kind: kind,
                  selected: _role == kind,
                  compact: true,
                  onTap: () => setState(() => _role = kind),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          _InfoBanner(
            text: 'Одна регистрация — все роли. Добавить другие роли '
                'можно в профиле.',
          ),
          const SizedBox(height: AppSpacing.x20),
          AppButton(
            label: 'Создать аккаунт',
            onPressed: _submit,
            isLoading: _loading,
          ),
          const SizedBox(height: AppSpacing.x16),
          Center(
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Уже есть аккаунт? ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.n500,
                      ),
                    ),
                    TextSpan(
                      text: 'Войти',
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
          const SizedBox(height: AppSpacing.x24),
        ],
      ),
    );
  }
}

extension on AppRoleKind {
  /// Маппинг UI-карточки на системную роль. Соответствие 1-к-1.
  SystemRole get systemRole => switch (this) {
        AppRoleKind.customer => SystemRole.customer,
        AppRoleKind.representative => SystemRole.representative,
        AppRoleKind.foreman => SystemRole.contractor,
        AppRoleKind.master => SystemRole.master,
      };
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsFill.info, size: 18, color: AppColors.brand),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.n700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

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
          Icon(
            PhosphorIconsFill.warningCircle,
            color: AppColors.redDot,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.redText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
