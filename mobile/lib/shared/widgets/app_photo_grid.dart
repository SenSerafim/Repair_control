import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'app_dashed_border.dart';

/// 4-column photo grid из дизайна `Кластер C` step-detail.
///
/// CSS-параметры:
/// - grid-template-columns: repeat(4, 1fr)
/// - gap: 8px
/// - aspect-ratio: 1
/// - border-radius: r12
/// - photo-add cell: dashed n200 + bg n50 + plus icon
class AppPhotoGrid extends StatelessWidget {
  const AppPhotoGrid({
    required this.imageUrls,
    this.onAdd,
    this.onTapPhoto,
    this.onDeletePhoto,
    this.maxColumns = 4,
    super.key,
  });

  final List<String> imageUrls;

  /// Вызывается при тапе на «+» cell. Если null — add-cell не показывается.
  final VoidCallback? onAdd;

  /// Колбэк при тапе на конкретное фото — для full-screen viewer.
  final void Function(int index)? onTapPhoto;

  /// Колбэк удаления (если есть — отрисовывается крестик в углу).
  final void Function(int index)? onDeletePhoto;

  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (var i = 0; i < imageUrls.length; i++)
        _PhotoCell(
          url: imageUrls[i],
          onTap: onTapPhoto == null ? null : () => onTapPhoto!(i),
          onDelete:
              onDeletePhoto == null ? null : () => onDeletePhoto!(i),
        ),
      if (onAdd != null) _AddCell(onTap: onAdd!),
    ];
    return GridView.count(
      crossAxisCount: maxColumns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: cells,
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({required this.url, this.onTap, this.onDelete});

  final String url;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.n100,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.n400,
                  ),
                ),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : Container(color: AppColors.n100),
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.overlayBackdrop,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.n0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddCell extends StatelessWidget {
  const _AddCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppDashedBorder(
        color: AppColors.n200,
        strokeWidth: 2,
        borderRadius: AppRadius.r12,
        padding: EdgeInsets.zero,
        child: Container(
          color: AppColors.n50,
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_rounded,
            size: 28,
            color: AppColors.n400,
          ),
        ),
      ),
    );
  }
}
