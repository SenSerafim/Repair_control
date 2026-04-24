import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'app_bottom_sheet.dart';

/// Что выбрал пользователь в photo-picker (s-photo-picker).
enum PhotoSource { camera, gallery, delete }

/// Bottom-sheet из HTML `s-photo-picker`: камера / галерея / удалить.
/// Возвращает [PhotoSource] или `null`, если пользователь закрыл sheet.
Future<PhotoSource?> showPhotoPickerSheet(
  BuildContext context, {
  bool allowDelete = true,
  String title = 'Фото профиля',
  String subtitle = 'Выберите источник фотографии',
}) {
  return showAppBottomSheet<PhotoSource>(
    context: context,
    child: _PhotoPickerSheet(
      title: title,
      subtitle: subtitle,
      allowDelete: allowDelete,
    ),
  );
}

class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet({
    required this.title,
    required this.subtitle,
    required this.allowDelete,
  });

  final String title;
  final String subtitle;
  final bool allowDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(title: title, subtitle: subtitle),
        _Tile(
          icon: Icons.photo_camera_outlined,
          iconBg: AppColors.brandLight,
          iconColor: AppColors.brand,
          title: 'Сделать фото',
          subtitle: 'Открыть камеру',
          onTap: () => Navigator.of(context).pop(PhotoSource.camera),
        ),
        const SizedBox(height: AppSpacing.x8),
        _Tile(
          icon: Icons.image_outlined,
          iconBg: AppColors.greenLight,
          iconColor: AppColors.greenDark,
          title: 'Из галереи',
          subtitle: 'Выбрать существующее фото',
          onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
        ),
        if (allowDelete) ...[
          const SizedBox(height: AppSpacing.x8),
          _Tile(
            icon: Icons.delete_outline_rounded,
            iconBg: AppColors.redBg,
            iconColor: AppColors.redDot,
            title: 'Удалить фото',
            subtitle: 'Вернуть инициалы',
            titleColor: AppColors.redDot,
            onTap: () => Navigator.of(context).pop(PhotoSource.delete),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.n200),
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      color: titleColor ?? AppColors.n900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.n400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
