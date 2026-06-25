import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/image_compress.dart';
import '../../../shared/widgets/widgets.dart';
import '../../approvals/data/approvals_repository.dart';
import '../../approvals/domain/approval.dart';

/// NEWFIX §4.1 — «Отправить на доработку».
/// Создаёт Approval scope=defect с фото-доказательством + описанием.
/// Адресат — бригадир (он маршрутизирует мастеру).
Future<bool> showReclamationSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String stepId,
  required String addresseeId,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    child: _ReclamationBody(
      projectId: projectId,
      stepId: stepId,
      addresseeId: addresseeId,
    ),
  );
  return result ?? false;
}

class _ReclamationBody extends ConsumerStatefulWidget {
  const _ReclamationBody({
    required this.projectId,
    required this.stepId,
    required this.addresseeId,
  });

  final String projectId;
  final String stepId;
  final String addresseeId;

  @override
  ConsumerState<_ReclamationBody> createState() => _ReclamationBodyState();
}

class _PickedPhoto {
  _PickedPhoto({required this.fileKey, required this.thumbnail});
  final String fileKey;
  final Uint8List thumbnail;
}

class _ReclamationBodyState extends ConsumerState<_ReclamationBody> {
  final _description = TextEditingController();
  final List<_PickedPhoto> _photos = [];
  bool _picking = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_picking || _submitting) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 100);
      if (picked == null) {
        if (mounted) setState(() => _picking = false);
        return;
      }
      final raw = await picked.readAsBytes();
      final compressed = compressImage(raw);
      if (compressed == null) {
        if (!mounted) return;
        setState(() {
          _picking = false;
          _error = 'Не удалось обработать фото';
        });
        return;
      }
      final repo = ref.read(approvalsRepositoryProvider);
      final presigned = await repo.presignDefectPhoto(
        mimeType: compressed.mimeType,
        sizeBytes: compressed.sizeBytes,
        originalName: picked.name,
      );
      await repo.uploadToStorage(
        presigned: presigned,
        bytes: compressed.bytes,
        mimeType: compressed.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _photos.add(
          _PickedPhoto(fileKey: presigned.fileKey, thumbnail: compressed.bytes),
        );
        _picking = false;
      });
    } on ApprovalsException catch (e) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = e.failure.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = 'Не удалось загрузить фото';
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final text = _description.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Опишите, что нужно доработать');
      return;
    }
    if (_photos.isEmpty) {
      setState(() => _error = 'Прикрепите хотя бы одно фото-доказательство');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(approvalsRepositoryProvider)
          .create(
            projectId: widget.projectId,
            scope: ApprovalScope.defect,
            addresseeId: widget.addresseeId,
            stepId: widget.stepId,
            payload: {'description': text},
            attachmentKeys: _photos.map((p) => p.fileKey).toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Отправлено на доработку',
        kind: AppToastKind.success,
      );
    } on ApprovalsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.failure.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(
            title: 'Отправить на доработку',
            subtitle:
                'Опишите проблему и приложите фото. Бригадир получит '
                'заявку и направит её мастеру.',
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
          const Text('Что нужно доработать', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
          TextField(
            controller: _description,
            maxLines: 4,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Опишите проблему подробно'),
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              const Text('Фото-доказательства', style: AppTextStyles.caption),
              const SizedBox(width: AppSpacing.x6),
              Text(
                '(${_photos.length})',
                style: AppTextStyles.caption.copyWith(color: AppColors.n400),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          if (_photos.isNotEmpty) ...[
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.x8),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.r8),
                      child: Image.memory(
                        _photos[i].thumbnail,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _submitting
                            ? null
                            : () => setState(() => _photos.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Камера'),
                  onPressed: (_picking || _submitting)
                      ? null
                      : () => _addPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Галерея'),
                  onPressed: (_picking || _submitting)
                      ? null
                      : () => _addPhoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Отправить',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: AppTextStyles.body.copyWith(color: AppColors.n500),
  filled: true,
  fillColor: AppColors.n0,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.r12),
    borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.r12),
    borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.r12),
    borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
  ),
);
