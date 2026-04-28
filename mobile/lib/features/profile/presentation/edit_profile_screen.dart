import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/profile_controller.dart';
import '../data/profile_repository.dart';

/// s-edit-profile — редактирование ФИО/email + аватар через PhotoPickerSheet.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
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
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      setState(() => _error = 'Заполните имя и фамилию');
      return;
    }
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
        message: 'Профиль сохранён',
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
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    return AppScaffold(
      showBack: true,
      title: 'Данные профиля',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.sh2,
                    ),
                    child: profile == null
                        ? const SizedBox.shrink()
                        : AppAvatar(
                            seed: profile.id,
                            name: '${profile.firstName} ${profile.lastName}',
                            imageUrl: profile.avatarUrl,
                            size: 88,
                            palette: AvatarPalette.blue,
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.n0, width: 2),
                        boxShadow: AppShadows.shBlue,
                      ),
                      child: Icon(
                        PhosphorIconsFill.camera,
                        size: 14,
                        color: AppColors.n0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: const Text(
                'Изменить фото',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x24),
          if (_error != null) ...[
            AppInlineError(message: _error!),
            const SizedBox(height: AppSpacing.x12),
          ],
          AppInput(
            controller: _firstName,
            label: 'Имя',
            placeholder: 'Имя',
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: _lastName,
            label: 'Фамилия',
            placeholder: 'Фамилия',
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: _email,
            label: 'Email',
            placeholder: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.x12),
          AppInput(
            controller: TextEditingController(text: profile?.phone ?? ''),
            label: 'Номер телефона',
            placeholder: '+7 (000) 000-00-00',
            enabled: false,
            helperText: 'Телефон нельзя изменить — это ваш логин',
          ),
          const SizedBox(height: AppSpacing.x32),
          AppButton(
            label: 'Сохранить',
            isLoading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: AppSpacing.x24),
        ],
      ),
    );
  }
}
