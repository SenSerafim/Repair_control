import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/stages_controller.dart';
import '../application/templates_controller.dart';
import '../data/stages_repository.dart';
import '_widgets/template_preview_body.dart';

/// c-template-preview — превью шаблона с CTA «Создать этап из шаблона».
class TemplatePreviewScreen extends ConsumerStatefulWidget {
  const TemplatePreviewScreen({
    required this.projectId,
    required this.templateId,
    super.key,
  });

  final String projectId;
  final String templateId;

  @override
  ConsumerState<TemplatePreviewScreen> createState() =>
      _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState
    extends ConsumerState<TemplatePreviewScreen> {
  bool _applying = false;

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final stage =
          await ref.read(stagesRepositoryProvider).applyTemplate(
                templateId: widget.templateId,
                projectId: widget.projectId,
              );
      ref.invalidate(stagesControllerProvider(widget.projectId));
      if (!mounted) return;
      context.go(
        AppRoutes.stageCreatedWith(
          projectId: widget.projectId,
          stageId: stage.id,
        ),
      );
    } on StagesException catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(templateDetailProvider(widget.templateId));
    return AppScaffold(
      showBack: true,
      title: 'Шаблон',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить шаблон',
          onRetry: () =>
              ref.invalidate(templateDetailProvider(widget.templateId)),
        ),
        data: (tpl) => TemplatePreviewBody(
          template: tpl,
          isApplying: _applying,
          onApply: _apply,
        ),
      ),
    );
  }
}
