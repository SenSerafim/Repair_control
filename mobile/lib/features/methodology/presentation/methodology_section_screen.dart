import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/methodology_controller.dart';

/// d-method-section — статьи одного раздела.
class MethodologySectionScreen extends ConsumerWidget {
  const MethodologySectionScreen({required this.sectionId, super.key});

  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(methodologySectionProvider(sectionId));

    return AppScaffold(
      showBack: true,
      title: 'Раздел',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить раздел',
          onRetry: () =>
              ref.invalidate(methodologySectionProvider(sectionId)),
        ),
        data: (section) {
          if (section.articles.isEmpty) {
            return AppEmptyState(
              title: section.title,
              subtitle: 'В этом разделе пока нет статей.',
              icon: Icons.article_outlined,
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(section.title, style: AppTextStyles.h1),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: section.articles.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.x8),
                  itemBuilder: (_, i) {
                    final a = section.articles[i];
                    return _ArticleRow(
                      title: a.title,
                      version: a.version,
                      onTap: () =>
                          context.push('/methodology/articles/${a.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({
    required this.title,
    required this.version,
    required this.onTap,
  });

  final String title;
  final int version;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.article_outlined,
              color: AppColors.brand,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(title, style: AppTextStyles.subtitle),
            ),
            Text('v$version', style: AppTextStyles.tiny),
            const SizedBox(width: AppSpacing.x6),
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
