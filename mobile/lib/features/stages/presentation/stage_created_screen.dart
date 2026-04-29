import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/widgets.dart';
import '_widgets/stage_created_success.dart';

/// c-stage-created — экран успешного создания этапа с 2 CTA.
///
/// stageId передаётся через query string `?stageId=...`, чтобы при
/// «Открыть этап» сразу зайти на нужный StageDetailScreen.
class StageCreatedScreen extends StatelessWidget {
  const StageCreatedScreen({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;

  /// Может быть null, если по какой-то причине stageId не передан в URL —
  /// тогда «Открыть этап» возвращает в общий список этапов.
  final String? stageId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: false,
      title: '',
      body: StageCreatedSuccess(
        onOpenStage: () {
          if (stageId != null) {
            context.go(
              AppRoutes.stageDetailWith(
                projectId: projectId,
                stageId: stageId!,
              ),
            );
          } else {
            context.go('/projects/$projectId/stages');
          }
        },
        onBackToList: () => context.go('/projects/$projectId/stages'),
      ),
    );
  }
}
