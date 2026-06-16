import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/step_detail_controller.dart';

/// c-add-photo — выбор «Камера»/«Галерея» для фото и «Видео-камера»/
/// «Видео-галерея» → image_picker → upload. Компрессия 1920/80 + EXIF-zero
/// только для фото (внутри `uploadPhoto`); видео грузится как есть
/// (`uploadVideo`). Бэк допускает video/mp4 + video/quicktime до 200 MB
/// (см. step-photos.service.ts).
Future<bool> showAddPhotoSheet(
  BuildContext context,
  WidgetRef ref, {
  required StepDetailKey key,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _AddPhotoBody(detailKey: key),
  );
  return result ?? false;
}

class _AddPhotoBody extends ConsumerStatefulWidget {
  const _AddPhotoBody({required this.detailKey});

  final StepDetailKey detailKey;

  @override
  ConsumerState<_AddPhotoBody> createState() => _AddPhotoBodyState();
}

class _AddPhotoBodyState extends ConsumerState<_AddPhotoBody> {
  bool _uploading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 100, // мы сами компрессим — не даём image_picker
      );
      if (picked == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      final failure = await ref
          .read(stepDetailProvider(widget.detailKey).notifier)
          .uploadPhoto(rawBytes: bytes, filename: picked.name);
      if (!mounted) return;
      if (failure == null) {
        Navigator.of(context).pop(true);
        AppToast.show(
          context,
          message: 'Фото загружено',
          kind: AppToastKind.success,
        );
      } else {
        setState(() {
          _error = failure.userMessage;
          _uploading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось получить фото';
        _uploading = false;
      });
    }
  }

  /// NEWFIX TZ-фронт §8 — видео в шаг. Без компрессии; бэк допускает до 200 MB.
  Future<void> _pickVideo(ImageSource source) async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: source);
      if (picked == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      // image_picker возвращает .mp4 на iOS/Android. Quicktime (.mov) тоже
      // допустим бэком — определяем по расширению, иначе fallback на mp4.
      final lower = picked.name.toLowerCase();
      final mime = lower.endsWith('.mov') ? 'video/quicktime' : 'video/mp4';
      final failure = await ref
          .read(stepDetailProvider(widget.detailKey).notifier)
          .uploadVideo(rawBytes: bytes, filename: picked.name, mimeType: mime);
      if (!mounted) return;
      if (failure == null) {
        Navigator.of(context).pop(true);
        AppToast.show(
          context,
          message: 'Видео загружено',
          kind: AppToastKind.success,
        );
      } else {
        setState(() {
          _error = failure.userMessage;
          _uploading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось получить видео';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Добавить фото или видео',
          subtitle:
              'Перед отправкой фото сжимается до 1920 px, 80% JPEG, EXIF '
              'очищается. Видео грузится как есть (до 200 MB).',
        ),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.redBg,
              borderRadius: AppRadius.card,
            ),
            child: Text(
              _error!,
              style: AppTextStyles.body.copyWith(color: AppColors.redText),
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
        ],
        _SourceTile(
          icon: Icons.photo_camera_outlined,
          label: 'Сделать фото',
          hint: 'Камера',
          onTap: _uploading ? null : () => _pick(ImageSource.camera),
        ),
        const SizedBox(height: AppSpacing.x10),
        _SourceTile(
          icon: Icons.photo_library_outlined,
          label: 'Выбрать фото из галереи',
          hint: 'Галерея',
          onTap: _uploading ? null : () => _pick(ImageSource.gallery),
        ),
        const SizedBox(height: AppSpacing.x10),
        _SourceTile(
          icon: Icons.videocam_outlined,
          label: 'Снять видео',
          hint: 'Видео-камера',
          onTap: _uploading ? null : () => _pickVideo(ImageSource.camera),
        ),
        const SizedBox(height: AppSpacing.x10),
        _SourceTile(
          icon: Icons.video_library_outlined,
          label: 'Выбрать видео из галереи',
          hint: 'Галерея',
          onTap: _uploading ? null : () => _pickVideo(ImageSource.gallery),
        ),
        if (_uploading) ...[
          const SizedBox(height: AppSpacing.x16),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppSpacing.x8),
          const Text(
            'Загружаем…',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.n200, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(icon, size: 20, color: AppColors.brand),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.subtitle),
                    Text(hint, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.n300),
            ],
          ),
        ),
      ),
    );
  }
}
