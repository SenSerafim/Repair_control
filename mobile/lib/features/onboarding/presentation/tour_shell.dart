import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/tour_anchor_registry.dart';
import '../application/tour_controller.dart';
import '../domain/tour_step.dart';
import 'tour_completion_screen.dart';
import 'tour_mock_screens.dart';
import 'welcome_tour_screen.dart';
import 'widgets/tour_bubble.dart';
import 'widgets/tour_overlay.dart';

/// Корень `/tour` route.
///
/// Архитектурное решение: тур использует **статические mock-экраны** вместо
/// реальных экранов с подменёнными репозиториями. Причина — overrides
/// `Provider<T>.overrideWithValue(...)` в этом setup'е иногда не цеплялись
/// к real-screen-ам (логи показывали 404/403 на /api/projects/demo-project),
/// и мы тратили циклы на дебаг Riverpod вместо доставки UX. Mock-экраны
/// самостоятельны: никаких сетевых вызовов, никаких провайдеров домена,
/// только статичный контент похожий по виду на боевые экраны.
class TourShell extends StatelessWidget {
  const TourShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // Изолированный реестр anchor-ей. Он живёт ровно в пределах /tour
      // route — ProviderScope создаёт child-container, при выходе из тура
      // container уничтожается, регистрация очищается.
      overrides: [
        tourAnchorRegistryProvider.overrideWithValue(TourAnchorRegistry()),
      ],
      child: const _TourBody(),
    );
  }
}

class _TourBody extends ConsumerWidget {
  const _TourBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tourControllerProvider);
    final step = state.current;
    final body = _screenFor(step.screenKey);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit(context, ref);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            body,
            TourOverlay(
              activeScreenKey: step.screenKey,
              bubbleBuilder: (ctx, s) => TourBubble(
                title: _titleFor(s),
                message: _messageFor(s),
                stepIndex: state.index,
                totalSteps: 14,
                onSkip: () => _confirmExit(ctx, ref),
                onBack: state.isFirst
                    ? null
                    : () => ref.read(tourControllerProvider.notifier).back(),
                onNext: () =>
                    ref.read(tourControllerProvider.notifier).advance(),
                onCutoutTapHint:
                    s.requiresUserTap ? 'или нажмите подсвеченную кнопку' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenFor(String screenKey) {
    switch (screenKey) {
      case 'welcome':
        return const WelcomeTourScreen();
      case 'console':
        return const TourMockConsoleScreen();
      case 'stages':
        return const TourMockStagesScreen();
      case 'stage_detail':
        return const TourMockStageDetailScreen();
      case 'step_detail':
        return const TourMockStepDetailScreen();
      case 'approvals':
        return const TourMockApprovalsScreen();
      case 'approval_detail':
        return const TourMockApprovalDetailScreen();
      case 'budget':
        return const TourMockBudgetScreen();
      case 'payments_list':
        return const TourMockPaymentsScreen();
      case 'materials':
        return const TourMockMaterialsScreen();
      case 'chats':
        return const TourMockChatsScreen();
      case 'chat_conversation':
        return const TourMockChatConversationScreen();
      case 'notifications':
        return const TourMockNotificationsScreen();
      case 'completion':
        return const TourCompletionScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  String _titleFor(TourStep step) {
    switch (step.id) {
      case 'welcome':
        return 'Привет!';
      case 'console':
        return 'Главный экран проекта';
      case 'stages':
        return 'Этапы';
      case 'stage_detail':
        return 'Детали этапа';
      case 'step_detail':
        return 'Шаг работы';
      case 'approvals':
        return 'Согласования';
      case 'approval_detail':
        return 'Решение по согласованию';
      case 'budget':
        return 'Бюджет проекта';
      case 'payments_list':
        return 'Платежи';
      case 'materials':
        return 'Материалы';
      case 'chats':
        return 'Чаты проекта';
      case 'chat_conversation':
        return 'Сообщения';
      case 'notifications':
        return 'Уведомления';
      case 'completion':
        return 'Готово!';
      default:
        return '';
    }
  }

  String _messageFor(TourStep step) {
    switch (step.id) {
      case 'welcome':
        return 'Покажу за 2 минуты, как пользоваться приложением. Можно пропустить.';
      case 'console':
        return 'Это главный экран проекта. Нажмите «Этапы» — там вся работа.';
      case 'stages':
        return 'Этапы проекта. Цвет показывает статус. Нажмите первый — посмотрим, что внутри.';
      case 'stage_detail':
        return 'Внутри этапа — шаги работы. Нажмите первый шаг.';
      case 'step_detail':
        return 'Шаг с фото, чек-листом, вопросами. Мастер отмечает готово, заказчик одобряет.';
      case 'approvals':
        return 'Здесь все согласования. Нажмите первое — увидите, как заказчик решает.';
      case 'approval_detail':
        return 'Заказчик одобряет или отклоняет. Решение видит вся команда.';
      case 'budget':
        return 'Бюджет проекта. Заказчик платит бригадиру, бригадир — мастеру.';
      case 'payments_list':
        return 'Все платежи. Каждый получатель подтверждает получение.';
      case 'materials':
        return 'Материалы: бригадир заказывает, чеки прикрепляются к заявке.';
      case 'chats':
        return 'Чаты проекта. Нажмите чат — посмотрите, как идёт переписка.';
      case 'chat_conversation':
        return 'Сообщения в реальном времени. Push приходит, даже когда приложение закрыто.';
      case 'notifications':
        return 'Все события проекта. Тап — откроется нужный экран.';
      case 'completion':
        return 'Создайте свой проект или присоединитесь по коду от бригадира.';
      default:
        return '';
    }
  }

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Прервать обучение?'),
        content: const Text(
          'Тур можно будет пройти позже из «Профиль → Пройти обучение».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Продолжить'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Прервать'),
          ),
        ],
      ),
    );
    if (exit ?? false) {
      unawaited(SystemSound.play(SystemSoundType.click));
      await ref.read(tourControllerProvider.notifier).cancel();
    }
  }
}
