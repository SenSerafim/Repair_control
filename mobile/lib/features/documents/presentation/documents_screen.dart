import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../exports/presentation/export_sheet.dart';
import '../../stages/application/stages_controller.dart';
import '../application/documents_controller.dart';
import '../domain/document.dart';

final _filterProvider =
    StateProvider.autoDispose<DocumentCategory?>((_) => null);

final _stageFilterProvider = StateProvider.autoDispose<String?>((_) => null);

final _listProvider = FutureProvider.autoDispose
    .family<List<Document>, String>((ref, projectId) async {
  final filter = ref.watch(_filterProvider);
  final stageId = ref.watch(_stageFilterProvider);
  return ref.watch(
    documentsListProvider(
      DocumentsListParams(
        projectId: projectId,
        category: filter,
        stageId: stageId,
      ),
    ).future,
  );
});

/// `f-docs` / `f-docs-empty` / `f-docs-filter` (`Кластер F`).
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_listProvider(projectId));
    final filter = ref.watch(_filterProvider);
    final canWrite = ref.watch(canInProjectProvider(
      (action: DomainAction.documentWrite, projectId: projectId),
    ));

    return AppScaffold(
      showBack: true,
      title: 'Документы',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          tooltip: 'Экспорт',
          icon: const Icon(Icons.cloud_download_outlined),
          onPressed: () =>
              showExportSheet(context, ref, projectId: projectId),
        ),
        if (canWrite)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _UploadIconButton(
              onTap: () async {
                final uploaded = await context.push<bool>(
                  '/projects/$projectId/documents/upload',
                );
                if (uploaded ?? false) {
                  ref.invalidate(_listProvider(projectId));
                }
              },
            ),
          ),
      ],
      body: Column(
        children: [
          _CategoryFilter(
            selected: filter,
            onChanged: (v) =>
                ref.read(_filterProvider.notifier).state = v,
          ),
          _StageFilter(projectId: projectId),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(
                skeleton: AppListSkeleton(itemHeight: 76),
              ),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить',
                onRetry: () => ref.invalidate(_listProvider(projectId)),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return AppEmptyState(
                    title: 'Нет документов',
                    subtitle: 'Загрузите документы проекта: планы, сметы, '
                        'чертежи',
                    icon: Icons.insert_drive_file_outlined,
                    actionLabel: canWrite ? 'Загрузить документ' : null,
                    onAction: canWrite
                        ? () async {
                            final uploaded = await context.push<bool>(
                              '/projects/$projectId/documents/upload',
                            );
                            if (uploaded ?? false) {
                              ref.invalidate(_listProvider(projectId));
                            }
                          }
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(_listProvider(projectId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _DocRow(
                      doc: docs[i],
                      onTap: () => context
                          .push(AppRoutes.documentDetailWith(docs[i].id)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadIconButton extends StatelessWidget {
  const _UploadIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.upload_file_rounded,
          size: 18,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});

  final DocumentCategory? selected;
  final ValueChanged<DocumentCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <AppFilterPillSpec>[
      const AppFilterPillSpec(id: '__all__', label: 'Все'),
      for (final c in DocumentCategory.values)
        AppFilterPillSpec(id: c.name, label: c.displayName),
    ];
    return AppFilterPillBar(
      chips: chips,
      activeId: selected?.name ?? '__all__',
      onSelect: (id) {
        if (id == '__all__') {
          onChanged(null);
        } else {
          onChanged(
            DocumentCategory.values.firstWhere((c) => c.name == id),
          );
        }
      },
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc, required this.onTap});
  final Document doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.n200),
            boxShadow: AppShadows.sh1,
          ),
          child: Row(
            children: [
              if (doc.isImage && (doc.thumbUrl ?? doc.url) != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Image.network(
                      doc.thumbUrl ?? doc.url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          AppDocTypeIcon(mimeType: doc.mimeType),
                    ),
                  ),
                )
              else
                AppDocTypeIcon(mimeType: doc.mimeType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.n800,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.category.displayName} · ${_sizeLabel(doc.sizeBytes)} · '
                      '${DateFormat('d MMM', 'ru').format(doc.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} КБ';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} МБ';
  }
}

class _StageFilter extends ConsumerWidget {
  const _StageFilter({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesControllerProvider(projectId));
    final selected = ref.watch(_stageFilterProvider);
    return stagesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stages) {
        if (stages.isEmpty) return const SizedBox.shrink();
        final chips = <AppFilterPillSpec>[
          const AppFilterPillSpec(id: '__all__', label: 'Все этапы'),
          for (final s in stages)
            AppFilterPillSpec(id: s.id, label: s.title),
        ];
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.n0,
            border: Border(bottom: BorderSide(color: AppColors.n100)),
          ),
          child: AppFilterPillBar(
            chips: chips,
            activeId: selected ?? '__all__',
            onSelect: (id) {
              ref.read(_stageFilterProvider.notifier).state =
                  id == '__all__' ? null : id;
            },
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          ),
        );
      },
    );
  }
}
