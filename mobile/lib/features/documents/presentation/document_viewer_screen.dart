import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/documents_controller.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

/// f-doc-viewer / f-doc-preview — inline-просмотрщик документов.
/// PDF — через pdfx (inline pinch-zoom).
/// Остальное (DOCX/XLSX/images) — плейсхолдер с кнопкой «Открыть внешним».
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
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = ref.read(documentsControllerProvider);
      final doc = await ref.read(documentByIdProvider(widget.documentId).future);
      if (!doc.isPdf) {
        if (mounted) {
          setState(() {
            _doc = doc;
            _loading = false;
          });
        }
        return;
      }
      final url = await controller.downloadUrl(doc.id);
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
              label: 'Скачать',
              icon: Icons.download_rounded,
              onPressed: _download,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download() async {
    try {
      final url = await ref
          .read(documentsControllerProvider)
          .downloadUrl(widget.documentId);
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Ссылка: $url',
        kind: AppToastKind.info,
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
