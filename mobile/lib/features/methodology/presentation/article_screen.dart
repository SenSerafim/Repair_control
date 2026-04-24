import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/methodology_controller.dart';

/// d-method-article — статья методички с body + метаданными.
class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(methodologyArticleProvider(articleId));

    return AppScaffold(
      showBack: true,
      title: 'Статья',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить статью',
          onRetry: () =>
              ref.invalidate(methodologyArticleProvider(articleId)),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(methodologyArticleProvider(articleId)),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x16),
            children: [
              Text(a.title, style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.x6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Версия ${a.version}',
                      style: AppTextStyles.tiny
                          .copyWith(color: AppColors.brand),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  Text(
                    'Обновлено ${DateFormat('d MMMM y', 'ru').format(a.updatedAt)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x20),
              Text(
                a.body,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.x32),
            ],
          ),
        ),
      ),
    );
  }
}
