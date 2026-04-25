import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/documents_controller.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

/// f-doc-upload — загрузка документа (dropzone + категория + название).
class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  PlatformFile? _file;
  int _size = 0;
  DocumentCategory _category = DocumentCategory.contract;
  final _titleCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'docx',
        'xlsx',
      ],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    setState(() {
      _file = picked;
      _size = picked.size;
      if (_titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = picked.name;
      }
    });
  }

  String _mime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument'
          '.spreadsheetml.sheet';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument'
          '.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  Future<void> _upload() async {
    if (_file == null || _busy) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Укажите название документа');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final mime = _mime(_file!.name);
      final bytes = await File(_file!.path!).readAsBytes();
      await ref.read(documentsControllerProvider).upload(
            projectId: widget.projectId,
            category: _category,
            title: title,
            mimeType: mime,
            bytes: bytes,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Документ загружен',
        kind: AppToastKind.success,
      );
    } on DocumentsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.failure.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: 'Загрузить документ',
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x16,
        AppSpacing.x16,
        AppSpacing.x24,
      ),
      body: ListView(
        children: [
          _Dropzone(file: _file, sizeBytes: _size, onPick: _pick),
          const SizedBox(height: AppSpacing.x20),
          Text(
            'Название',
            style: AppTextStyles.micro.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x6),
          AppInput(
            controller: _titleCtrl,
            placeholder: 'Например, Смета_Электрика',
          ),
          const SizedBox(height: AppSpacing.x16),
          Text(
            'Категория',
            style: AppTextStyles.micro.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x8),
          Wrap(
            spacing: AppSpacing.x6,
            runSpacing: AppSpacing.x6,
            children: [
              for (final c in DocumentCategory.values)
                _CategoryChip(
                  label: c.displayName,
                  active: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.x12),
            AppInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.x24),
          if (_busy) ...[
            const AppUploadProgressBar(progress: null),
            const SizedBox(height: AppSpacing.x12),
          ],
          AppButton(
            label: _busy ? 'Загружаем…' : 'Загрузить',
            onPressed: _busy || _file == null ? null : _upload,
          ),
        ],
      ),
    );
  }
}

class _Dropzone extends StatelessWidget {
  const _Dropzone({
    required this.file,
    required this.sizeBytes,
    required this.onPick,
  });

  final PlatformFile? file;
  final int sizeBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final selected = file != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.r20),
      child: DottedBorderBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.upload_file_rounded,
                size: 26,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              selected ? file!.name : 'Нажмите для выбора файла',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              selected
                  ? _sizeLabel(sizeBytes)
                  : 'PDF, JPG, PNG, DOCX, XLSX · до 50 МБ',
              style: AppTextStyles.caption.copyWith(color: AppColors.n400),
            ),
          ],
        ),
      ),
    );
  }

  String _sizeLabel(int b) {
    if (b < 1024) return '$b Б';
    if (b < 1024 * 1024) return '${(b / 1024).round()} КБ';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} МБ';
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppDashedBorder(child: child);
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x6,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.brandLight : AppColors.n0,
          border: Border.all(
            color: active ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? AppColors.brand : AppColors.n500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
