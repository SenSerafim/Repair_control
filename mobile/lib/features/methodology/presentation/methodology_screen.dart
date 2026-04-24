import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/methodology_controller.dart';

/// d-methodology / d-method-empty.
class MethodologyScreen extends ConsumerWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(methodologySectionsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Методичка',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.push('/methodology/search'),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () =>
              ref.read(methodologySectionsProvider.notifier).refresh(),
        ),
        data: (sections) {
          if (sections.isEmpty) {
            return const AppEmptyState(
              title: 'Методичка пуста',
              subtitle:
                  'Разделы и статьи добавляет администратор. Пока тут ничего нет.',
              icon: Icons.menu_book_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(methodologySectionsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: sections.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x10),
              itemBuilder: (_, i) {
                final s = sections[i];
                return _SectionRow(
                  title: s.title,
                  articleCount: s.articles.length,
                  onTap: () =>
                      context.push('/methodology/sections/${s.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.title,
    required this.articleCount,
    required this.onTap,
  });

  final String title;
  final int articleCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: const Icon(
                Icons.folder_special_outlined,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  const SizedBox(height: 2),
                  Text(
                    '$articleCount статей',
                    style: AppTextStyles.caption,
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
