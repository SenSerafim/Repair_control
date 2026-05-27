import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/exports_repository.dart';
import '../domain/export_job.dart';
import 'export_sheet.dart';

final _exportsListProvider = FutureProvider.autoDispose
    .family<List<ExportJob>, String>((ref, projectId) async {
      return ref.read(exportsRepositoryProvider).list(projectId);
    });

/// Список экспортов проекта (PDF ленты + ZIP проекта). Открывается из
/// FeedScreen/DocumentsScreen и push-deep-link для kind=export_*.
class ExportsListScreen extends ConsumerWidget {
  const ExportsListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_exportsListProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Экспорты',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'Новый экспорт',
          onPressed: () async {
            final created = await showExportSheet(
              context,
              ref,
              projectId: projectId,
            );
            if (created != null) {
              ref.invalidate(_exportsListProvider(projectId));
            }
          },
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(_exportsListProvider(projectId)),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return AppEmptyState(
              title: 'Экспортов ещё нет',
              subtitle:
                  'Сформируйте полный PDF-отчёт проекта, PDF-ленту за период '
                  'или ZIP со всеми файлами.',
              icon: Icons.cloud_download_outlined,
              actionLabel: 'Создать',
              onAction: () async {
                final created = await showExportSheet(
                  context,
                  ref,
                  projectId: projectId,
                );
                if (created != null) {
                  ref.invalidate(_exportsListProvider(projectId));
                }
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_exportsListProvider(projectId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: jobs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x10),
              itemBuilder: (_, i) => _ExportCard(job: jobs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ExportCard extends ConsumerStatefulWidget {
  const _ExportCard({required this.job});

  final ExportJob job;

  @override
  ConsumerState<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<_ExportCard> {
  bool _busy = false;

  ExportJob get job => widget.job;

  bool get _isDone => job.status == ExportStatus.done;

  /// Карточка done-задания тапается целиком. Если `downloadUrl` уже есть —
  /// сразу открываем в браузере. Если нет (S3 не успел сгенерить ссылку
  /// в момент list-запроса, либо backend по какой-то причине не вложил её) —
  /// тянем job через `GET /api/exports/:id`, который всегда presign'ит URL.
  /// Это убирает баг «нажимаю на Готов — ничего не происходит».
  Future<void> _openOrFetch() async {
    if (_busy || !_isDone) return;
    final urlNow = job.downloadUrl;
    if (urlNow != null && urlNow.isNotEmpty) {
      await _launchOrCopy(urlNow);
      return;
    }
    setState(() => _busy = true);
    try {
      final fresh = await ref.read(exportsRepositoryProvider).get(job.id);
      if (!mounted) return;
      final url = fresh.downloadUrl;
      if (url == null || url.isEmpty) {
        AppToast.show(
          context,
          message:
              'Файл ещё не готов. Потяните вниз для обновления через несколько секунд.',
          kind: AppToastKind.error,
        );
        return;
      }
      await _launchOrCopy(url);
    } on ExportsException catch (e) {
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
        message: 'Не удалось получить ссылку. Попробуйте ещё раз.',
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Скачивает файл через наш API и открывает системным viewer-ом.
  /// Раньше использовался launchUrl на presigned-S3 URL — Selectel
  /// отдавал redirect, но Android не открывал результат. Теперь:
  ///   1. dio.download (auth + baseUrl автоматически) — файл локально
  ///   2. OpenFilex.open — system intent / preview
  /// URL приходит относительный (`/api/exports/:id/file`), но если
  /// сервер вернул абсолютный (back-compat) — тоже работает.
  Future<void> _launchOrCopy(String url) async {
    try {
      final tmpDir = await getTemporaryDirectory();
      final urlPath = Uri.tryParse(url)?.path ?? url;
      final ext = p.extension(urlPath).isNotEmpty
          ? p.extension(urlPath)
          : _extFromKind(job.kind);
      final filename = 'export_${job.id.substring(0, 8)}$ext';
      final file = File(p.join(tmpDir.path, filename));
      await ref.read(dioProvider).download(url, file.path);
      if (!mounted) return;
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        AppToast.show(
          context,
          message: 'Не удалось открыть файл (${result.message})',
          kind: AppToastKind.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Не удалось скачать файл. Скопировали ссылку.',
        kind: AppToastKind.error,
      );
      await Clipboard.setData(ClipboardData(text: url));
    }
  }

  String _extFromKind(ExportKind kind) {
    switch (kind) {
      case ExportKind.feedPdf:
      case ExportKind.projectReportPdf:
        return '.pdf';
      case ExportKind.projectZip:
        return '.zip';
    }
  }

  Future<void> _copyLink() async {
    final url = job.downloadUrl;
    if (url == null) {
      // У карточки в списке URL может ещё не быть — подтянем через get()
      // и положим в clipboard в один тап.
      try {
        final fresh = await ref.read(exportsRepositoryProvider).get(job.id);
        final freshUrl = fresh.downloadUrl;
        if (freshUrl == null || freshUrl.isEmpty) {
          if (!mounted) return;
          AppToast.show(
            context,
            message: 'Файл ещё не готов.',
            kind: AppToastKind.error,
          );
          return;
        }
        await Clipboard.setData(ClipboardData(text: freshUrl));
      } catch (_) {
        if (!mounted) return;
        AppToast.show(
          context,
          message: 'Не удалось получить ссылку.',
          kind: AppToastKind.error,
        );
        return;
      }
    } else {
      await Clipboard.setData(ClipboardData(text: url));
    }
    if (!mounted) return;
    AppToast.show(
      context,
      message: 'Ссылка на файл скопирована',
      kind: AppToastKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: _isDone ? _openOrFetch : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.n200, width: 1.5),
            boxShadow: AppShadows.sh1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: job.status.semaphore.bg,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            switch (job.kind) {
                              ExportKind.feedPdf =>
                                Icons.picture_as_pdf_outlined,
                              ExportKind.projectReportPdf =>
                                Icons.description_outlined,
                              ExportKind.projectZip =>
                                Icons.folder_zip_outlined,
                            },
                            color: job.status.semaphore.text,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.kind.displayName,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat(
                            'd MMM y · HH:mm',
                            'ru',
                          ).format(job.createdAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: job.status.displayName,
                    semaphore: job.status.semaphore,
                  ),
                ],
              ),
              if (job.status == ExportStatus.failed &&
                  (job.failureReason?.isNotEmpty ?? false)) ...[
                const SizedBox(height: AppSpacing.x10),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x10),
                  decoration: BoxDecoration(
                    color: AppColors.redBg,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Text(
                    job.failureReason!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.redText,
                    ),
                  ),
                ),
              ],
              if (_isDone) ...[
                const SizedBox(height: AppSpacing.x10),
                AppButton(
                  label: 'Скачать',
                  icon: Icons.download_rounded,
                  isLoading: _busy,
                  onPressed: _busy ? null : _openOrFetch,
                ),
                const SizedBox(height: AppSpacing.x6),
                AppButton(
                  label: 'Скопировать ссылку',
                  icon: Icons.link_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _copyLink,
                ),
              ],
              if (job.expiresAt != null && _isDone) ...[
                const SizedBox(height: 4),
                Text(
                  'Ссылка действует до '
                  '${DateFormat('d MMM y · HH:mm', 'ru').format(job.expiresAt!)}',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
