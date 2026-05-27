import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/api_error.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/documents_controller.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

/// Лимит размера файла на клиенте — должен совпадать с docs/-policy
/// в `backend/libs/files/src/files.module.ts`.
const _maxSizeMb = 200;
const _maxSizeBytes = _maxSizeMb * 1024 * 1024;

/// f-doc-upload — загрузка документа: файл + название + дата + описание.
/// Принимает любые типы файлов (фото, видео, PDF, офис, архивы и т.д.).
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
  DocumentCategory _category = DocumentCategory.other;
  DateTime? _documentDate;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Прогресс 0..1; null = неопределённый (presign/confirm фазы).
  double? _progress;
  int _sentBytes = 0;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('screen disposed');
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      // Любой файл — фото, видео, PDF, документ, архив.
      type: FileType.any,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    setState(() {
      _file = picked;
      _size = picked.size;
      _error = null;
      if (_titleCtrl.text.trim().isEmpty) {
        // Заголовок без расширения — оно потом всё равно по mime.
        final base = picked.name.contains('.')
            ? picked.name.substring(0, picked.name.lastIndexOf('.'))
            : picked.name;
        _titleCtrl.text = base;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _documentDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() => _documentDate = picked);
    }
  }

  Future<void> _upload() async {
    if (_file == null || _busy) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Укажите название документа');
      return;
    }
    if (_size > _maxSizeBytes) {
      setState(() => _error = 'Файл больше $_maxSizeMb МБ');
      return;
    }
    final filePath = _file!.path;
    if (filePath == null) {
      setState(() => _error = 'Не удалось получить путь к файлу');
      return;
    }
    final cancel = CancelToken();
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
      _sentBytes = 0;
      _cancelToken = cancel;
    });
    try {
      final mime = _mimeFromName(_file!.name);
      final desc = _descCtrl.text.trim();
      await ref
          .read(documentsControllerProvider)
          .upload(
            projectId: widget.projectId,
            category: _category,
            title: title,
            mimeType: mime,
            filePath: filePath,
            sizeBytes: _size,
            description: desc.isEmpty ? null : desc,
            documentDate: _documentDate,
            cancelToken: cancel,
            onProgress: (fraction, sent, _) {
              if (!mounted) return;
              setState(() {
                _progress = fraction;
                _sentBytes = sent;
              });
            },
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
      if (e.apiError.kind == ApiErrorKind.cancelled) {
        AppToast.show(
          context,
          message: 'Загрузка отменена',
          kind: AppToastKind.info,
        );
      } else {
        setState(() => _error = _errorMessage(e.apiError));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _cancelToken = null;
        });
      }
    }
  }

  void _cancel() {
    _cancelToken?.cancel('user cancelled');
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
          _Dropzone(
            file: _file,
            sizeBytes: _size,
            mimeType: _file == null ? null : _mimeFromName(_file!.name),
            onPick: _busy ? null : _pick,
          ),
          const SizedBox(height: AppSpacing.x20),
          Text(
            'Название',
            style: AppTextStyles.micro.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x6),
          AppInput(
            controller: _titleCtrl,
            placeholder: 'Например, Договор подряда от 15.01',
            enabled: !_busy,
          ),
          const SizedBox(height: AppSpacing.x16),
          Text(
            'Дата документа',
            style: AppTextStyles.micro.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x6),
          _DateField(
            value: _documentDate,
            onTap: _busy ? () {} : _pickDate,
            onClear: (_documentDate == null || _busy)
                ? null
                : () => setState(() => _documentDate = null),
          ),
          const SizedBox(height: AppSpacing.x16),
          Text(
            'Краткое описание',
            style: AppTextStyles.micro.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x6),
          AppInput(
            controller: _descCtrl,
            placeholder: 'Что это за документ — чтобы потом найти',
            maxLines: 4,
            enabled: !_busy,
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
                  onTap: _busy ? null : () => setState(() => _category = c),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.x12),
            AppInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.x24),
          if (_busy) ...[
            _UploadProgressPanel(
              progress: _progress,
              sentBytes: _sentBytes,
              totalBytes: _size,
              onCancel: _cancel,
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          AppButton(
            label: _busy ? _busyLabel(_progress) : 'Загрузить',
            onPressed: _busy || _file == null ? null : _upload,
          ),
        ],
      ),
    );
  }

  String _busyLabel(double? p) {
    if (p == null) return 'Подготовка…';
    if (p >= 1.0) return 'Завершаем…';
    return 'Загружаем… ${(p * 100).round()}%';
  }

  /// Маппинг ApiErrorKind → понятное человеческое сообщение для UX.
  /// Кастомизация поверх дефолта AuthFailure.userMessage — там слишком
  /// общие фразы для load-flow.
  String _errorMessage(ApiError e) {
    switch (e.kind) {
      case ApiErrorKind.network:
        return 'Нет связи. Проверьте интернет и попробуйте ещё раз.';
      case ApiErrorKind.timeout:
        return 'Загрузка слишком долгая. Сеть нестабильна — '
            'попробуйте подключиться к Wi-Fi.';
      case ApiErrorKind.validation:
        // 413 на S3-прокси прилетает чаще всего как validation/4xx.
        if (e.statusCode == 413) return 'Файл больше $_maxSizeMb МБ';
        return e.message ?? 'Проверьте поля формы';
      case ApiErrorKind.forbidden:
        return 'У вашей роли нет прав загружать документы '
            'в этот проект.';
      case ApiErrorKind.rateLimited:
        return 'Слишком часто. Подождите немного.';
      case ApiErrorKind.server:
        return 'Сервер недоступен. Попробуйте позже.';
      case ApiErrorKind.cancelled:
        return 'Загрузка отменена';
      case ApiErrorKind.unauthorized:
        return 'Сессия истекла. Войдите заново.';
      case ApiErrorKind.notFound:
        return 'Проект не найден или удалён.';
      case ApiErrorKind.conflict:
        return 'Состояние изменилось. Обновите экран.';
      case ApiErrorKind.unknown:
        return e.message ?? 'Не удалось загрузить файл';
    }
  }
}

/// Маппинг расширения в mime — для всех типов из docs/-policy.
/// Для неизвестных расширений отдаём application/octet-stream.
String _mimeFromName(String name) {
  final lower = name.toLowerCase();
  final dot = lower.lastIndexOf('.');
  final ext = dot < 0 ? '' : lower.substring(dot + 1);
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'heic':
      return 'image/heic';
    case 'heif':
      return 'image/heif';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'avi':
      return 'video/x-msvideo';
    case 'mkv':
      return 'video/x-matroska';
    case 'webm':
      return 'video/webm';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument'
          '.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument'
          '.spreadsheetml.sheet';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument'
          '.presentationml.presentation';
    case 'txt':
      return 'text/plain';
    case 'csv':
      return 'text/csv';
    case 'zip':
      return 'application/zip';
    case 'rar':
      return 'application/x-rar-compressed';
    case '7z':
      return 'application/x-7z-compressed';
    default:
      return 'application/octet-stream';
  }
}

class _Dropzone extends StatelessWidget {
  const _Dropzone({
    required this.file,
    required this.sizeBytes,
    required this.mimeType,
    required this.onPick,
  });

  final PlatformFile? file;
  final int sizeBytes;
  final String? mimeType;
  final VoidCallback? onPick;

  bool get _isImage => mimeType?.startsWith('image/') ?? false;
  bool get _isVideo => mimeType?.startsWith('video/') ?? false;

  @override
  Widget build(BuildContext context) {
    final selected = file != null;
    final tooLarge = sizeBytes > _maxSizeBytes;
    // Для image/* показываем превью самого файла, для остальных —
    // тематическую иконку (PDF/doc/video/архив).
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.r20),
      child: DottedBorderBox(
        child: selected && _isImage && !tooLarge && file?.path != null
            ? _imagePreview(file!.path!)
            : _placeholder(tooLarge: tooLarge, selected: selected),
      ),
    );
  }

  /// Превью выбранного изображения — компактное (хедер сверху), чтобы
  /// форма ниже не утопала под фотку. Файл локальный, грузится мгновенно.
  Widget _imagePreview(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x8,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: Image.file(
              File(path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: AppColors.n100,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.n400,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file!.name,
                  style: AppTextStyles.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _sizeLabel(sizeBytes),
                  style: AppTextStyles.caption.copyWith(color: AppColors.n400),
                ),
                const SizedBox(height: 6),
                Text(
                  'Нажмите, чтобы выбрать другой файл',
                  style: AppTextStyles.micro.copyWith(color: AppColors.brand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder({required bool tooLarge, required bool selected}) {
    final iconBg = tooLarge ? AppColors.redBg : AppColors.brandLight;
    final iconColor = tooLarge ? AppColors.redDot : AppColors.brand;
    final icon = tooLarge
        ? Icons.error_outline_rounded
        : !selected
            ? Icons.upload_file_rounded
            : _isVideo
                ? Icons.videocam_rounded
                : _iconForMime(mimeType ?? '');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 26, color: iconColor),
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
              : 'Любой файл (фото, видео, PDF, doc, архив) · до '
                    '$_maxSizeMb МБ',
          style: AppTextStyles.caption.copyWith(
            color: tooLarge ? AppColors.redDot : AppColors.n400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _iconForMime(String mime) {
    if (mime == 'application/pdf') return Icons.picture_as_pdf_rounded;
    if (mime.contains('word')) return Icons.description_rounded;
    if (mime.contains('sheet') || mime.contains('excel')) {
      return Icons.table_chart_rounded;
    }
    if (mime.contains('presentation') || mime.contains('powerpoint')) {
      return Icons.slideshow_rounded;
    }
    if (mime.contains('zip') || mime.contains('rar') || mime.contains('7z')) {
      return Icons.folder_zip_rounded;
    }
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.startsWith('video/')) return Icons.videocam_rounded;
    if (mime.startsWith('text/')) return Icons.article_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _sizeLabel(int b) {
    if (b < 1024) return '$b Б';
    if (b < 1024 * 1024) return '${(b / 1024).round()} КБ';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} МБ';
  }
}

/// Карточка прогресса загрузки: бар + проценты + sent/total + Отменить.
class _UploadProgressPanel extends StatelessWidget {
  const _UploadProgressPanel({
    required this.progress,
    required this.sentBytes,
    required this.totalBytes,
    required this.onCancel,
  });

  final double? progress;
  final int sentBytes;
  final int totalBytes;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final pct = progress == null ? null : (progress! * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pct == null
                      ? 'Загружаем…'
                      : pct >= 100
                          ? 'Завершаем загрузку…'
                          : 'Загрузка $pct%',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.brand,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onCancel,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x6,
                    vertical: 2,
                  ),
                  child: Text(
                    'Отменить',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          AppUploadProgressBar(progress: progress),
          const SizedBox(height: AppSpacing.x6),
          Text(
            _bytesLine(sentBytes, totalBytes),
            style: AppTextStyles.micro.copyWith(color: AppColors.n500),
          ),
        ],
      ),
    );
  }

  String _bytesLine(int sent, int total) {
    if (total <= 0) return _fmt(sent);
    return '${_fmt(sent)} из ${_fmt(total)}';
  }

  String _fmt(int b) {
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
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
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.brand : AppColors.n500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? 'Выберите дату документа'
        : DateFormat('d MMMM y', 'ru').format(value!);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x14,
        ),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: value == null ? AppColors.n200 : AppColors.brand,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: value == null ? AppColors.n400 : AppColors.brand,
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                formatted,
                style: AppTextStyles.subtitle.copyWith(
                  color: value == null ? AppColors.n400 : AppColors.n800,
                  fontWeight: value == null
                      ? FontWeight.w500
                      : FontWeight.w700,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.n400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
