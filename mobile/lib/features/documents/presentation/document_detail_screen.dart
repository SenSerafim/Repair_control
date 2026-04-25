import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.documentViewWith(doc.id)),
          child: _Preview(doc: doc),
        ),
        const SizedBox(height: AppSpacing.x16),
        _MetaCard(doc: doc),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Открыть',
          icon: Icons.visibility_outlined,
          onPressed: () =>
              context.push(AppRoutes.documentViewWith(doc.id)),
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Скачать',
          variant: AppButtonVariant.secondary,
          icon: Icons.download_rounded,
          onPressed: () => _download(context, ref),
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Поделиться',
          variant: AppButtonVariant.secondary,
          icon: Icons.share_outlined,
          onPressed: () => _share(context, ref),
        ),
        if (canDelete) ...[
          const SizedBox(height: AppSpacing.x8),
          AppButton(
            label: 'Удалить',
            variant: AppButtonVariant.destructive,
            icon: Icons.delete_outline_rounded,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      final url = await ref
          .read(documentsControllerProvider)
          .downloadUrl(doc.id);
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: 'Ссылка на файл скопирована',
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
          // Sharing через копирование ссылки в буфер обмена —
          // backend не предоставляет прямой POST /chats/.../share.
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
      ),
    );
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
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.n200),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(doc.category.icon, size: 40, color: AppColors.n400),
          const SizedBox(height: AppSpacing.x8),
          Text(
            doc.isPdf
                ? 'PDF'
                : doc.isImage
                    ? 'Изображение'
                    : 'Документ',
            style: AppTextStyles.caption.copyWith(color: AppColors.n500),
          ),
        ],
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
  });

  final String docTitle;
  final String docSize;
  final List<Chat> chats;
  final ValueChanged<String> onPickChat;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(
          title: 'Поделиться',
          subtitle: '$docTitle · $docSize',
        ),
        for (final c in chats) ...[
          _ShareTile(
            icon: Icons.forum_outlined,
            iconBg: AppColors.brandLight,
            iconColor: AppColors.brand,
            title: c.title ?? c.type.displayName,
            subtitle: c.type.displayName,
            onTap: () => onPickChat(c.id),
          ),
          const SizedBox(height: AppSpacing.x6),
        ],
        _ShareTile(
          icon: Icons.link_rounded,
          iconBg: AppColors.n100,
          iconColor: AppColors.n700,
          title: 'Скопировать ссылку',
          subtitle: 'Ссылка на файл в буфер обмена',
          onTap: onCopyLink,
        ),
      ],
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.n400),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.n300,
            ),
          ],
        ),
      ),
    );
  }
}
