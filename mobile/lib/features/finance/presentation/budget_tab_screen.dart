import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/application/projects_list_controller.dart'
    show activeProjectsProvider;
import '../../projects/domain/project.dart';

/// Top-level вкладка «Бюджет» в bottom-nav (NEWFIX TZ-2 §6 — Бюджет на
/// месте Команды). Бюджет per-project, поэтому показываем список проектов
/// → тап ведёт в `/projects/:id/budget`.
class BudgetTabScreen extends ConsumerWidget {
  const BudgetTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeProjectsProvider);
    return AppScaffold(
      title: 'Бюджет',
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить список проектов',
          onRetry: () => ref.invalidate(activeProjectsProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const AppEmptyState(
              title: 'Пока нет проектов',
              subtitle:
                  'Создайте проект на вкладке «Проекты», '
                  'затем сможете смотреть бюджет.',
              icon: Icons.account_balance_wallet_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.x16),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x10),
            itemBuilder: (_, i) => _ProjectBudgetTile(project: projects[i]),
          );
        },
      ),
    );
  }
}

class _ProjectBudgetTile extends StatelessWidget {
  const _ProjectBudgetTile({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final total = project.totalBudget;
    return Material(
      color: AppColors.n0,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: () => context.push('/projects/${project.id}/budget'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: AppColors.n200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: AppTextStyles.h2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.address != null && project.address!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          project.address!,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.x6),
                    Text(
                      _formatRub(total),
                      style: AppTextStyles.h2.copyWith(color: AppColors.brand),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.n400),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRub(int kopecks) {
    final rub = kopecks ~/ 100;
    final str = rub.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return '${buf.toString()} ₽';
  }
}
