import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/widgets.dart';

/// Корневая вкладка «Команда» в HomeShell. Команда формируется в рамках
/// конкретного проекта — здесь показываем подсказку и кнопку «К проектам»,
/// откуда пользователь зайдёт в нужный проект и откроет TeamScreen.
class ContractorsScreen extends StatelessWidget {
  const ContractorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Команда',
      body: AppEmptyState(
        title: 'Команда формируется в проекте',
        subtitle:
            'Откройте проект и перейдите на вкладку «Команда» — там список '
            'участников, ролей и прав представителя.',
        icon: Icons.people_outline_rounded,
        actionLabel: 'К проектам',
        onAction: () => context.go(AppRoutes.projects),
      ),
    );
  }
}
