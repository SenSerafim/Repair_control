import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/config/app_providers.dart';
import '../../../../core/theme/tokens.dart';
import '../../data/knowledge_repository.dart';
import '../../domain/knowledge_asset.dart';
import 'knowledge_video_player.dart';

/// Универсальный виджет для отрисовки asset любой категории. Запрашивает
/// presigned download-URL из бекенда и рендерит соответствующий контент.
class KnowledgeAssetView extends ConsumerStatefulWidget {
  const KnowledgeAssetView({super.key, required this.asset});
  final KnowledgeAsset asset;

  @override
  ConsumerState<KnowledgeAssetView> createState() => _KnowledgeAssetViewState();
}

class _KnowledgeAssetViewState extends ConsumerState<KnowledgeAssetView> {
  String? _url;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    try {
      final repo = ref.read(knowledgeRepositoryProvider);
      final url = await repo.getAssetUrl(widget.asset.articleId, widget.asset.id);
      if (!mounted) return;
      setState(() {
        _url = url;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.asset.caption;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _url == null) {
      return _ErrorBox(message: _error ?? 'не удалось получить ссылку');
    }

    final url = _url!;
    final body = switch (widget.asset.kind) {
      KnowledgeAssetKind.image => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => const AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(color: AppColors.n100),
            ),
            errorWidget: (_, __, ___) =>
                const _ErrorBox(message: 'не удалось загрузить изображение'),
          ),
        ) as Widget,
      KnowledgeAssetKind.video => KnowledgeVideoPlayer(url: url),
      KnowledgeAssetKind.file => _FileTile(asset: widget.asset, url: url),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          body,
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x6),
            Text(
              caption,
              style: const TextStyle(
                color: AppColors.n500,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FileTile extends ConsumerStatefulWidget {
  const _FileTile({required this.asset, required this.url});
  final KnowledgeAsset asset;
  final String url;

  @override
  ConsumerState<_FileTile> createState() => _FileTileState();
}

class _FileTileState extends ConsumerState<_FileTile> {
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      final dio = ref.read(dioProvider);
      final tempPath = '/tmp/${widget.asset.id}_${widget.asset.fileKey.split('/').last}';
      await dio.download(widget.url, tempPath,
          options: dio_pkg.Options(receiveTimeout: const Duration(minutes: 2)));
      await OpenFilex.open(tempPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть файл: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      onTap: _busy ? null : _open,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            const Icon(PhosphorIconsFill.filePdf, color: AppColors.brand, size: 26),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.asset.caption ?? widget.asset.fileKey.split('/').last,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.n900,
                    ),
                  ),
                  Text(
                    '${(widget.asset.sizeBytes / 1024 / 1024).toStringAsFixed(2)} МБ',
                    style: const TextStyle(fontSize: 12, color: AppColors.n500),
                  ),
                ],
              ),
            ),
            if (_busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.download_outlined,
                  size: 22, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.redText, fontSize: 13),
      ),
    );
  }
}
