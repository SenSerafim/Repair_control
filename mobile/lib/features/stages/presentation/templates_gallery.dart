import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/stages_controller.dart';
import '../application/templates_controller.dart';
import '../data/stages_repository.dart';
import '../domain/template.dart';

/// c-templates — галерея шаблонов (платформенные + пользовательские).
class TemplatesGallery extends ConsumerWidget {
  const TemplatesGallery({required this.onPick, super.key});

  final ValueChanged<StageTemplate> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(platformTemplatesProvider);
    final user = ref.watch(userTemplatesProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        _Section(
          title: 'Платформенные',
          async: platform,
          emptyLabel: 'Платформенные шаблоны не загружены.',
          onPick: onPick,
        ),
        const SizedBox(height: AppSpacing.x20),
        _Section(
          title: 'Мои шаблоны',
          async: user,
          emptyLabel: 'Пока нет своих шаблонов. Сохраните этап как '
              'шаблон — он появится здесь.',
          onPick: onPick,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.async,
    required this.emptyLabel,
    required this.onPick,
  });

  final String title;
  final AsyncValue<List<StageTemplate>> async;
  final String emptyLabel;
  final ValueChanged<StageTemplate> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.x4),
          child: Text(title, style: AppTextStyles.micro),
        ),
        const SizedBox(height: AppSpacing.x8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.x16),
            child: AppLoadingState(),
          ),
          error: (e, _) => Text(
            'Не удалось загрузить',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.redDot),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.x16),
                decoration: BoxDecoration(
                  color: AppColors.n100,
                  borderRadius: AppRadius.card,
                ),
                child:
                    Text(emptyLabel, style: AppTextStyles.caption),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (_, i) => _TemplateCard(
                template: items[i],
                onTap: () => onPick(items[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final StageTemplate template;
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
          boxShadow: AppShadows.sh1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: const Icon(
                Icons.layers_outlined,
                size: 20,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            Text(
              template.title,
              style: AppTextStyles.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (template.description != null)
              Text(
                template.description!,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                '${template.steps.length} шагов',
                style: AppTextStyles.caption,
              ),
          ],
        ),
      ),
    );
  }
}

/// c-template-preview — список шагов шаблона перед применением.
Future<bool> showTemplatePreview(
  BuildContext context,
  WidgetRef ref, {
  required StageTemplate template,
  required String projectId,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _Preview(template: template, projectId: projectId),
  );
  return result ?? false;
}

class _Preview extends ConsumerStatefulWidget {
  const _Preview({required this.template, required this.projectId});

  final StageTemplate template;
  final String projectId;

  @override
  ConsumerState<_Preview> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<_Preview> {
  bool _submitting = false;
  String? _error;

  Future<void> _apply() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(stagesRepositoryProvider).applyTemplate(
            templateId: widget.template.id,
            projectId: widget.projectId,
          );
      ref.invalidate(stagesControllerProvider(widget.projectId));
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppToast.show(
        context,
        message: 'Этап из шаблона создан',
        kind: AppToastKind.success,
      );
    } on StagesException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.failure.userMessage;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomSheetHeader(
            title: template.title,
            subtitle:
                template.description ?? '${template.steps.length} шагов',
          ),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.x12),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: AppRadius.card,
              ),
              child: Text(
                _error!,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.redText),
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: template.steps.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x4),
              itemBuilder: (_, i) {
                final step = template.steps[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x12,
                    vertical: AppSpacing.x10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.n100,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius:
                              BorderRadius.circular(AppRadius.r8),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: AppTextStyles.micro
                              .copyWith(color: AppColors.brand),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x10),
                      Expanded(
                        child: Text(step.title, style: AppTextStyles.body),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Применить к проекту',
            isLoading: _submitting,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}
