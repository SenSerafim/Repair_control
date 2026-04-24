import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

final _filterProvider =
    StateProvider.autoDispose<DocumentCategory?>((_) => null);

final _listProvider = FutureProvider.autoDispose
    .family<List<Document>, String>((ref, projectId) async {
  final filter = ref.watch(_filterProvider);
  return ref.read(documentsRepositoryProvider).list(
        projectId: projectId,
        category: filter,
      );
});

/// f-docs / f-docs-empty / f-docs-filter.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_listProvider(projectId));
    final filter = ref.watch(_filterProvider);

    return AppScaffold(
      showBack: true,
      title: 'Документы',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          tooltip: 'Загрузить',
          onPressed: () async {
            final uploaded = await context.push<bool>(
              '/projects/$projectId/documents/upload',
            );
            if (uploaded ?? false) {
              ref.invalidate(_listProvider(projectId));
            }
          },
          icon: const Icon(Icons.upload_file_rounded, color: AppColors.brand),
        ),
      ],
      body: Column(
        children: [
          _CategoryFilter(
            selected: filter,
            onChanged: (v) =>
                ref.read(_filterProvider.notifier).state = v,
          ),
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
                    title: filter == null
                        ? 'Документов пока нет'
                        : 'В этой категории пусто',
                    subtitle: filter == null
                        ? 'Загрузите договор, акт, смету — всё хранится в '
                            'рамках проекта.'
                        : null,
                    icon: Icons.insert_drive_file_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(_listProvider(projectId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x8),
                    itemBuilder: (_, i) => _DocRow(
                      doc: docs[i],
                      onTap: () =>
                          context.push('/documents/${docs[i].id}'),
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

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});

  final DocumentCategory? selected;
  final ValueChanged<DocumentCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        children: [
          _chip('Все', active: selected == null, onTap: () => onChanged(null)),
          for (final c in DocumentCategory.values) ...[
            const SizedBox(width: AppSpacing.x8),
            _chip(
              c.displayName,
              active: selected == c,
              onTap: () => onChanged(c),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, {required bool active, required VoidCallback onTap}) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x6,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.n100,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.n0 : AppColors.n700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc, required this.onTap});
  final Document doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200, width: 1.5),
        boxShadow: AppShadows.sh1,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Icon(doc.category.icon, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: AppTextStyles.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${doc.category.displayName} · ${_sizeLabel(doc.sizeBytes)} · '
                  '${DateFormat('d MMM', 'ru').format(doc.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.n400,
          ),
        ],
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
