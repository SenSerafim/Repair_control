import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/profile_controller.dart';
import '../data/profile_repository.dart';

/// s-edit-profile — редактирование firstName/lastName/email.
/// Аватар — в отдельном sheet (PhotoPickerSheet) — ссылается из этой формы.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileControllerProvider).value;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _email = TextEditingController(text: p?.email ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure =
        await ref.read(profileControllerProvider.notifier).updateProfile(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      setState(() => _error = failure.userMessage);
    } else {
      AppToast.show(
        context,
        message: 'Профиль обновлён',
        kind: AppToastKind.success,
      );
      await Navigator.of(context).maybePop();
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showPhotoPickerSheet(
      context,
      title: 'Фото профиля',
      subtitle: 'Выберите источник фотографии',
    );
    if (source == null || !mounted) return;
    if (source == PhotoSource.delete) {
      await _updateAvatar(null);
      return;
    }
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (x == null || !mounted) return;
    await _uploadAvatar(File(x.path), x.name);
  }

  Future<void> _uploadAvatar(File file, String name) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(profileRepositoryProvider);
      final size = await file.length();
      final mime =
          name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final presigned = await repo.presignUpload(
        originalName: name,
        mimeType: mime,
        sizeBytes: size,
        scope: 'avatar',
      );
      final bytes = await file.readAsBytes();
      final raw = Dio();
      await raw.put<void>(
        presigned.url,
        data: bytes,
        options: Options(
          headers: {...presigned.headers, 'Content-Type': mime},
        ),
      );
      await _updateAvatar(presigned.key);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось загрузить фото');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateAvatar(String? avatarKey) async {
    final failure =
        await ref.read(profileControllerProvider.notifier).updateProfile(
              avatarUrl: avatarKey,
            );
    if (!mounted) return;
    if (failure == null) {
      AppToast.show(
        context,
        message: avatarKey == null ? 'Фото удалено' : 'Фото обновлено',
        kind: AppToastKind.success,
      );
    } else {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Личные данные',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.x16),
            Center(
              child: AppButton(
                label: 'Сменить фото',
                variant: AppButtonVariant.secondary,
                onPressed: _pickPhoto,
                fullWidth: false,
              ),
            ),
            const SizedBox(height: AppSpacing.x20),
            if (_error != null) ...[
              AppInlineError(message: _error!),
              const SizedBox(height: AppSpacing.x12),
            ],
            const Text('Имя', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
              decoration: _dec('Ваше имя'),
            ),
            const SizedBox(height: AppSpacing.x12),
            const Text('Фамилия', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введите фамилию'
                  : null,
              decoration: _dec('Ваша фамилия'),
            ),
            const SizedBox(height: AppSpacing.x12),
            const Text('E-mail (опционально)', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!RegExp(r'^.+@.+\..+$').hasMatch(v.trim())) {
                  return 'Введите корректный email';
                }
                return null;
              },
              decoration: _dec('name@example.com'),
            ),
            const SizedBox(height: AppSpacing.x24),
            AppButton(
              label: 'Сохранить',
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
        filled: true,
        fillColor: AppColors.n0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
