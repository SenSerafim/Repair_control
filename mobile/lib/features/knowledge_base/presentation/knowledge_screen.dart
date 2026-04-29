import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/knowledge_controller.dart';
import '../domain/knowledge_category.dart';

/// Главный экран Базы знаний. Если задан moduleSlug в query — показываем
/// контекстные категории конкретного модуля проекта; иначе — глобальные.
class KnowledgeScreen extends ConsumerWidget {
  const KnowledgeScreen({super.key, this.moduleSlug});

  final String? moduleSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = moduleSlug == null
        ? const KnowledgeCategoriesFilter(scope: KnowledgeCategoryScope.global)
        : KnowledgeCategoriesFilter(
            scope: KnowledgeCategoryScope.projectModule,
            moduleSlug: moduleSlug,
          );
    final async = ref.watch(knowledgeCategoriesProvider(filter));

    return AppScaffold(
      showBack: true,
      title: moduleSlug == null ? 'База знаний' : 'Справка: $moduleSlug',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (_, __) => AppErrorState(
          title: 'Не удалось загрузить базу знаний',
          onRetry: () => ref.invalidate(knowledgeCategoriesProvider(filter)),
        ),
        data: (cats) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
          children: [
            // Поиск.
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              onTap: () => context.push(AppRoutes.knowledgeSearch),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x12,
                  vertical: AppSpacing.x12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  border: Border.all(color: AppColors.n200),
                ),
                child: const Row(
                  children: [
                    Icon(PhosphorIconsFill.magnifyingGlass,
                        color: AppColors.n400, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Поиск по статьям…',
                      style: TextStyle(color: AppColors.n400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            if (cats.isEmpty)
              const AppEmptyState(
                title: 'Здесь пока пусто',
                subtitle: 'Администратор добавит обучающие материалы.',
              )
            else
              AppMenuGroup(
                children: [
                  for (final c in cats)
                    AppMenuRow(
                      icon: PhosphorIconsFill.bookOpen,
                      iconBg: AppColors.brandLight,
                      iconColor: AppColors.brand,
                      label: c.title,
                      value: '${c.articleCount} статей',
                      onTap: () => context
                          .push(AppRoutes.knowledgeCategoryWith(c.id)),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.x24),
          ],
        ),
      ),
    );
  }
}
