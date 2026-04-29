import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/knowledge_controller.dart';

class KnowledgeCategoryScreen extends ConsumerWidget {
  const KnowledgeCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(knowledgeCategoryDetailProvider(categoryId));

    return AppScaffold(
      showBack: true,
      title: async.value?.category.title ?? 'Категория',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (_, __) => AppErrorState(
          title: 'Не удалось загрузить категорию',
          onRetry: () =>
              ref.invalidate(knowledgeCategoryDetailProvider(categoryId)),
        ),
        data: (detail) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
          children: [
            if (detail.category.description != null) ...[
              Text(
                detail.category.description!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.n500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
            ],
            if (detail.articles.isEmpty)
              const AppEmptyState(
                title: 'В категории пока нет статей',
              )
            else
              AppMenuGroup(
                children: [
                  for (final a in detail.articles)
                    AppMenuRow(
                      label: a.title,
                      onTap: () => context
                          .push(AppRoutes.knowledgeArticleWith(a.id)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
