import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/documents_controller.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

/// f-doc-viewer / f-doc-preview — inline-просмотрщик документов.
/// PDF — через pdfx (inline pinch-zoom), изображения — InteractiveViewer
/// поверх Image.network. Office-форматы — кнопка «Скопировать ссылку»
/// (полноценный inline-viewer DOCX/XLSX out-of-scope для S6–S17).
class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({required this.documentId, super.key});

  final String documentId;

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState
    extends ConsumerState<DocumentViewerScreen> {
  PdfController? _pdf;
  Document? _doc;
  String? _imageUrl;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final controller = ref.read(documentsControllerProvider);
      final doc = await ref.read(documentByIdProvider(widget.documentId).future);

      if (doc.isPdf) {
        // Если бэкенд приложил presigned `url` — используем его, иначе
        // догружаем через download endpoint.
        final url = doc.url ?? await controller.downloadUrl(doc.id);
        final bytes = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (!mounted) return;
        _pdf = PdfController(
          document: PdfDocument.openData(Uint8List.fromList(bytes.data!)),
        );
        setState(() {
          _doc = doc;
          _loading = false;
        });
        return;
      }

      if (doc.isImage) {
        final url = doc.url ?? await controller.downloadUrl(doc.id);
        if (!mounted) return;
        setState(() {
          _doc = doc;
          _imageUrl = url;
          _loading = false;
        });
        return;
      }

      // Office / прочее — inline-рендер не поддерживаем.
      if (mounted) {
        setState(() {
          _doc = doc;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить документ';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdf?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: true,
      title: _doc?.title ?? 'Документ',
      padding: EdgeInsets.zero,
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const AppLoadingState(branded: true);
    }
    if (_error != null) {
      return AppErrorState(title: _error!, onRetry: _load);
    }
    final doc = _doc!;
    if (doc.isPdf && _pdf != null) {
      return PdfView(controller: _pdf!);
    }
    if (doc.isImage && _imageUrl != null) {
      return ColoredBox(
        color: Colors.black,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Center(
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  'Не удалось загрузить изображение',
                  style:
                      AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(doc.category.icon, size: 64, color: AppColors.n300),
          const SizedBox(height: AppSpacing.x12),
          Text(doc.title, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.x4),
          Text(
            doc.mimeType,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.n500),
          ),
          const SizedBox(height: AppSpacing.x16),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.x24),
            child: AppButton(
              label: 'Открыть в системе',
              icon: Icons.open_in_new_rounded,
              onPressed: _openExternal,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.x24),
            child: AppButton(
              label: 'Скопировать ссылку',
              variant: AppButtonVariant.secondary,
              icon: Icons.link_rounded,
              onPressed: _copyLink,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternal() async {
    try {
      final url = _doc?.url ??
          await ref
              .read(documentsControllerProvider)
              .downloadUrl(widget.documentId);
      final tmpDir = await getTemporaryDirectory();
      final safeTitle = (_doc?.title ?? widget.documentId)
          .replaceAll(RegExp(r'[^A-Za-z0-9._\-А-Яа-я ]'), '_');
      final filename = '${widget.documentId}__$safeTitle';
      final hasExt = p.extension(filename).isNotEmpty;
      final ext = hasExt ? '' : _extFromMime(_doc?.mimeType ?? '');
      final file = File(p.join(tmpDir.path, '$filename$ext'));
      final raw = Dio();
      try {
        await raw.download(url, file.path);
      } finally {
        raw.close();
      }
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        AppToast.show(
          context,
          message: 'Не удалось открыть файл (${result.message})',
          kind: AppToastKind.error,
        );
      }
    } on DocumentsException catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Не удалось скачать файл',
        kind: AppToastKind.error,
      );
    }
  }

  String _extFromMime(String mime) {
    switch (mime) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'application/pdf':
        return '.pdf';
      case 'application/vnd.openxmlformats-officedocument'
          '.spreadsheetml.sheet':
        return '.xlsx';
      case 'application/vnd.openxmlformats-officedocument'
          '.wordprocessingml.document':
        return '.docx';
      default:
        return '';
    }
  }

  Future<void> _copyLink() async {
    try {
      final url = await ref
          .read(documentsControllerProvider)
          .downloadUrl(widget.documentId);
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Ссылка скопирована',
        kind: AppToastKind.success,
      );
    } on DocumentsException catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }
}
