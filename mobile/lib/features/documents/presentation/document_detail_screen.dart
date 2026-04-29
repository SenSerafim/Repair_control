import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../chat/data/chats_repository.dart';
import '../../chat/domain/chat.dart';
import '../application/documents_controller.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

/// f-doc-detail — превью + meta + Download/Share/Delete.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(documentByIdProvider(documentId));

    return AppScaffold(
      showBack: true,
      title: 'Документ',
      padding: const EdgeInsets.all(AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось открыть',
          onRetry: () => ref.invalidate(documentByIdProvider(documentId)),
        ),
        data: (doc) => _DetailView(doc: doc),
      ),
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.doc});

  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = ref.watch(canProvider(DomainAction.documentDelete));
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.documentViewWith(doc.id)),
          child: _Preview(doc: doc),
        ),
        const SizedBox(height: AppSpacing.x16),
        _MetaCard(doc: doc),
        const SizedBox(height: AppSpacing.x16),
        _OutlinedDocAction(
          label: 'Скачать',
          icon: Icons.download_rounded,
          iconColor: AppColors.brand,
          onTap: () => _download(context, ref),
        ),
        const SizedBox(height: 8),
        _OutlinedDocAction(
          label: 'Поделиться',
          icon: Icons.share_outlined,
          iconColor: AppColors.n500,
          onTap: () => _share(context, ref),
        ),
        if (canDelete) ...[
          const SizedBox(height: 8),
          _OutlinedDocAction(
            label: 'Удалить',
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.redDot,
            destructive: true,
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      final file = await _downloadToTemp(ref);
      if (!context.mounted) return;
      final result = await OpenFilex.open(file.path);
      if (!context.mounted) return;
      if (result.type != ResultType.done) {
        AppToast.show(
          context,
          message: 'Не удалось открыть файл (${result.message})',
          kind: AppToastKind.error,
        );
      }
    } on DocumentsException catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: 'Не удалось скачать файл',
        kind: AppToastKind.error,
      );
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final chats = await ref
        .read(chatsRepositoryProvider)
        .listProject(doc.projectId);
    if (!context.mounted) return;
    await showAppBottomSheet<void>(
      context: context,
      child: _ShareSheet(
        docTitle: doc.title,
        docSize: _sizeLabel(doc.sizeBytes),
        chats: chats,
        onPickChat: (id) async {
          Navigator.of(context).pop();
          try {
            final url = await ref
                .read(documentsControllerProvider)
                .downloadUrl(doc.id);
            if (!context.mounted) return;
            await Clipboard.setData(ClipboardData(text: url));
            if (!context.mounted) return;
            unawaited(context.push(AppRoutes.chatDetailWith(id)));
            AppToast.show(
              context,
              message: 'Ссылка скопирована — вставьте в чат',
              kind: AppToastKind.info,
            );
          } on DocumentsException catch (e) {
            if (!context.mounted) return;
            AppToast.show(
              context,
              message: e.failure.userMessage,
              kind: AppToastKind.error,
            );
          }
        },
        onCopyLink: () async {
          try {
            final url = await ref
                .read(documentsControllerProvider)
                .downloadUrl(doc.id);
            if (!context.mounted) return;
            await Clipboard.setData(ClipboardData(text: url));
            if (!context.mounted) return;
            Navigator.of(context).pop();
            AppToast.show(
              context,
              message: 'Ссылка скопирована',
              kind: AppToastKind.success,
            );
          } on DocumentsException catch (e) {
            if (!context.mounted) return;
            AppToast.show(
              context,
              message: e.failure.userMessage,
              kind: AppToastKind.error,
            );
          }
        },
        onSystemShare: () async {
          Navigator.of(context).pop();
          try {
            final file = await _downloadToTemp(ref);
            await Share.shareXFiles(
              [XFile(file.path, mimeType: doc.mimeType)],
              text: doc.title,
            );
          } on DocumentsException catch (e) {
            if (!context.mounted) return;
            AppToast.show(
              context,
              message: e.failure.userMessage,
              kind: AppToastKind.error,
            );
          } catch (_) {
            if (!context.mounted) return;
            AppToast.show(
              context,
              message: 'Не удалось поделиться файлом',
              kind: AppToastKind.error,
            );
          }
        },
      ),
    );
  }

  /// Скачивает документ во временную папку. Использует presigned URL
  /// (он не требует JWT-авторизации). Имя файла — `<id>__<title>` чтобы
  /// избежать коллизий и сохранить расширение для open_filex.
  Future<File> _downloadToTemp(WidgetRef ref) async {
    final url = doc.url ??
        await ref.read(documentsControllerProvider).downloadUrl(doc.id);
    final tmpDir = await getTemporaryDirectory();
    final safeTitle = doc.title.replaceAll(RegExp(r'[^A-Za-z0-9._\-А-Яа-я ]'), '_');
    final filename = '${doc.id}__$safeTitle';
    final ext = p.extension(filename).isEmpty
        ? _extFromMime(doc.mimeType)
        : '';
    final file = File(p.join(tmpDir.path, '$filename$ext'));
    final raw = Dio();
    try {
      await raw.download(url, file.path);
    } finally {
      raw.close();
    }
    return file;
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showAppBottomSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'Удалить документ?',
            subtitle: 'Действие нельзя отменить.',
          ),
          AppButton(
            label: 'Удалить',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(documentsControllerProvider).delete(
            id: doc.id,
            projectId: doc.projectId,
          );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on DocumentsException catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  String _sizeLabel(int b) {
    if (b < 1024) return '$b Б';
    if (b < 1024 * 1024) return '${(b / 1024).round()} КБ';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} МБ';
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.doc});
  final Document doc;

  @override
  Widget build(BuildContext context) {
    final previewUrl = doc.thumbUrl ?? doc.url;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.n200),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: doc.isImage && previewUrl != null
          ? Image.network(
              previewUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (_, __, ___) => _PlaceholderIcon(doc: doc),
            )
          : _PlaceholderIcon(doc: doc),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.doc});
  final Document doc;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppDocTypeIcon(mimeType: doc.mimeType, size: 56),
        const SizedBox(height: 10),
        const Text(
          'Нажмите для просмотра',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.n400,
          ),
        ),
      ],
    );
  }
}

class _OutlinedDocAction extends StatelessWidget {
  const _OutlinedDocAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.redDot : AppColors.n700;
    final bg = destructive ? AppColors.redBg : AppColors.n0;
    final border = destructive
        ? const Color(0xFFFECACA)
        : AppColors.n200;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.doc});
  final Document doc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.n200),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        children: [
          _row('Файл', doc.title),
          _row('Размер', _size(doc.sizeBytes)),
          _row('Категория', doc.category.displayName, valueColor: AppColors.brand),
          _row(
            'Дата',
            DateFormat('dd.MM.yyyy, HH:mm', 'ru').format(doc.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              k,
              style: AppTextStyles.caption.copyWith(color: AppColors.n500),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                v,
                style: AppTextStyles.subtitle.copyWith(
                  color: valueColor ?? AppColors.n800,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );

  String _size(int b) {
    if (b < 1024) return '$b Б';
    if (b < 1024 * 1024) return '${(b / 1024).round()} КБ';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} МБ';
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({
    required this.docTitle,
    required this.docSize,
    required this.chats,
    required this.onPickChat,
    required this.onCopyLink,
    required this.onSystemShare,
  });

  final String docTitle;
  final String docSize;
  final List<Chat> chats;
  final ValueChanged<String> onPickChat;
  final VoidCallback onCopyLink;
  final VoidCallback onSystemShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Поделиться',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.n900,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '$docTitle · $docSize',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.n400,
            ),
          ),
        ),
        AppOptionRow(
          icon: Icons.send_rounded,
          iconBg: AppColors.brand,
          iconFg: AppColors.n0,
          title: 'Отправить через…',
          subtitle: 'WhatsApp, Telegram, почта',
          onTap: onSystemShare,
        ),
        const SizedBox(height: 10),
        for (final c in chats) ...[
          AppOptionRow(
            icon: c.type == ChatType.project
                ? Icons.home_outlined
                : c.type == ChatType.stage
                    ? Icons.layers_outlined
                    : Icons.person_outline,
            iconBg: AppColors.brandLight,
            iconFg: AppColors.brand,
            title: c.title ?? c.type.displayName,
            subtitle: '${c.type.displayName} · ${c.participants.length} '
                'участников',
            onTap: () => onPickChat(c.id),
          ),
          const SizedBox(height: 10),
        ],
        AppOptionRow(
          icon: Icons.link_rounded,
          iconBg: AppColors.n100,
          iconFg: AppColors.n600,
          title: 'Скопировать ссылку',
          subtitle: 'Ссылка на файл в буфер обмена',
          onTap: onCopyLink,
        ),
      ],
    );
  }
}
