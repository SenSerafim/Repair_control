import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
            final created =
                await showExportSheet(context, ref, projectId: projectId);
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
              subtitle: 'Создайте PDF-отчёт ленты или ZIP всего проекта.',
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

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.job});

  final ExportJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Icon(
                  job.kind == ExportKind.feedPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.folder_zip_outlined,
                  color: job.status.semaphore.text,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.kind.displayName, style: AppTextStyles.subtitle),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM y · HH:mm', 'ru')
                          .format(job.createdAt),
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
          if (job.status == ExportStatus.done &&
              (job.downloadUrl?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.x10),
            AppButton(
              label: 'Скопировать ссылку',
              icon: Icons.link_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => _copyLink(context),
            ),
          ],
          if (job.expiresAt != null && job.status == ExportStatus.done) ...[
            const SizedBox(height: 4),
            Text(
              'Ссылка действует до '
              '${DateFormat('d MMM y · HH:mm', 'ru').format(job.expiresAt!)}',
              style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    final url = job.downloadUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: 'Ссылка на файл скопирована',
      kind: AppToastKind.success,
    );
  }
}
