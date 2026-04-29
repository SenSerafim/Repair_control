import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/methodology_controller.dart';
import 'methodology_screen.dart';

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
          final tone = MethodologySectionTone.fromTitle(section.title);
          if (section.articles.isEmpty) {
            return AppEmptyState(
              title: section.title,
              subtitle: 'В этом разделе пока нет статей.',
              icon: Icons.article_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x24,
            ),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tone.bg,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Icon(tone.icon, color: tone.fg, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: AppTextStyles.h1.copyWith(fontSize: 22),
                        ),
                        Text(
                          '${section.articles.length} '
                          '${_articlesWord(section.articles.length)}',
                          style: AppTextStyles.tiny
                              .copyWith(color: AppColors.n500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x16),
              for (var i = 0; i < section.articles.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.x10),
                _ArticleRow(
                  title: section.articles[i].title,
                  version: section.articles[i].version,
                  tone: tone,
                  onTap: () => context.push(
                    '/methodology/articles/${section.articles[i].id}',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _articlesWord(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'статья';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'статьи';
  }
  return 'статей';
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({
    required this.title,
    required this.version,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final int version;
  final MethodologySectionTone tone;
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
          border: Border.all(color: AppColors.n200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: Icon(
                Icons.article_outlined,
                color: tone.fg,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.n900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Версия $version',
                    style: AppTextStyles.tiny.copyWith(color: AppColors.n500),
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
