import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/templates_controller.dart';
import '../domain/template.dart';
import '_widgets/template_card.dart';

/// c-templates — список шаблонов для применения к проекту.
///
/// Платформенные шаблоны загружаются из [platformTemplatesProvider], под ними
/// — пользовательские из [userTemplatesProvider]. Tap → preview-экран.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformAsync = ref.watch(platformTemplatesProvider);
    final userAsync = ref.watch(userTemplatesProvider);

    return AppScaffold(
      showBack: true,
      title: 'Шаблоны этапов',
      padding: EdgeInsets.zero,
      body: platformAsync.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить шаблоны',
          onRetry: () => ref.invalidate(platformTemplatesProvider),
        ),
        data: (platform) {
          if (platform.isEmpty) {
            return const AppEmptyState(
              title: 'Шаблонов нет',
              icon: Icons.dashboard_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x32,
            ),
            children: [
              _SectionLabel('Предустановленные · ${platform.length}'),
              const SizedBox(height: AppSpacing.x10),
              for (final t in platform) ...[
                TemplateCard(
                  template: t,
                  onTap: () => _openPreview(context, t),
                ),
                const SizedBox(height: AppSpacing.x8),
              ],
              userAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) {
                  if (user.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.x12),
                      _SectionLabel('Мои шаблоны · ${user.length}'),
                      const SizedBox(height: AppSpacing.x10),
                      for (final t in user) ...[
                        TemplateCard(
                          template: t,
                          onTap: () => _openPreview(context, t),
                        ),
                        const SizedBox(height: AppSpacing.x8),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, StageTemplate t) {
    context.push(
      AppRoutes.stagesTemplatePreviewWith(
        projectId: projectId,
        templateId: t.id,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.tiny.copyWith(
        color: AppColors.n400,
        letterSpacing: 0.6,
      ),
    );
  }
}
