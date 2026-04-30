import '../domain/tour_step.dart';
import 'demo_data.dart';

/// Сценарий демо-тура: 14 последовательных шагов.
///
/// Все тексты — через ARB-ключи `tour_step_*_title` / `_message`. Маршруты
/// для информационных шагов (`requiresUserTap: false`) указаны в
/// [TourStep.routeOnAdvance]; для тап-шагов маршрут происходит через
/// нормальную навигацию, инициированную пользователем.
class TourScript {
  TourScript._();

  static final List<TourStep> steps = [
    // 1 — Welcome
    const TourStep(
      id: 'welcome',
      screenKey: 'welcome',
      titleKey: 'tour_step_welcome_title',
      messageKey: 'tour_step_welcome_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/projects/${DemoData.projectId}',
    ),
    // 2 — Console (главный экран проекта)
    const TourStep(
      id: 'console',
      screenKey: 'console',
      anchorId: 'console.stages_tile',
      titleKey: 'tour_step_console_title',
      messageKey: 'tour_step_console_message',
    ),
    // 3 — Stages (список этапов)
    const TourStep(
      id: 'stages',
      screenKey: 'stages',
      anchorId: 'stages.first_stage_card',
      titleKey: 'tour_step_stages_title',
      messageKey: 'tour_step_stages_message',
    ),
    // 4 — Stage detail (описание этапа и шагов)
    const TourStep(
      id: 'stage_detail',
      screenKey: 'stage_detail',
      anchorId: 'stage_detail.first_step',
      titleKey: 'tour_step_stage_detail_title',
      messageKey: 'tour_step_stage_detail_message',
    ),
    // 5 — Step detail (чеклист, фото, вопросы)
    const TourStep(
      id: 'step_detail',
      screenKey: 'step_detail',
      anchorId: 'step_detail.complete_button',
      titleKey: 'tour_step_step_detail_title',
      messageKey: 'tour_step_step_detail_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/projects/${DemoData.projectId}/approvals',
    ),
    // 6 — Approvals (список согласований)
    const TourStep(
      id: 'approvals',
      screenKey: 'approvals',
      anchorId: 'approvals.first_approval',
      titleKey: 'tour_step_approvals_title',
      messageKey: 'tour_step_approvals_message',
    ),
    // 7 — Approval detail (одобрение/отклонение)
    const TourStep(
      id: 'approval_detail',
      screenKey: 'approval_detail',
      anchorId: 'approval_detail.approve_button',
      titleKey: 'tour_step_approval_detail_title',
      messageKey: 'tour_step_approval_detail_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/projects/${DemoData.projectId}/budget',
    ),
    // 8 — Budget (бюджет проекта)
    const TourStep(
      id: 'budget',
      screenKey: 'budget',
      anchorId: 'budget.payments_tab',
      titleKey: 'tour_step_budget_title',
      messageKey: 'tour_step_budget_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/projects/${DemoData.projectId}/payments',
    ),
    // 9 — Payments list (список платежей)
    const TourStep(
      id: 'payments_list',
      screenKey: 'payments_list',
      anchorId: 'payments_list.first_payment',
      titleKey: 'tour_step_payments_list_title',
      messageKey: 'tour_step_payments_list_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/projects/${DemoData.projectId}/materials',
    ),
    // 10 — Materials
    const TourStep(
      id: 'materials',
      screenKey: 'materials',
      anchorId: 'materials.first_request',
      titleKey: 'tour_step_materials_title',
      messageKey: 'tour_step_materials_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/projects/${DemoData.projectId}/chats',
    ),
    // 11 — Chats (список чатов)
    const TourStep(
      id: 'chats',
      screenKey: 'chats',
      anchorId: 'chats.first_chat',
      titleKey: 'tour_step_chats_title',
      messageKey: 'tour_step_chats_message',
    ),
    // 12 — Chat conversation
    const TourStep(
      id: 'chat_conversation',
      screenKey: 'chat_conversation',
      anchorId: 'chat_conversation.input',
      titleKey: 'tour_step_chat_conversation_title',
      messageKey: 'tour_step_chat_conversation_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/notifications',
    ),
    // 13 — Notifications
    const TourStep(
      id: 'notifications',
      screenKey: 'notifications',
      anchorId: 'notifications.first_item',
      titleKey: 'tour_step_notifications_title',
      messageKey: 'tour_step_notifications_message',
      requiresUserTap: false,
      routeOnAdvance: '/tour/completion',
    ),
    // 14 — Completion
    const TourStep(
      id: 'completion',
      screenKey: 'completion',
      titleKey: 'tour_step_completion_title',
      messageKey: 'tour_step_completion_message',
      requiresUserTap: false,
    ),
  ];
}
