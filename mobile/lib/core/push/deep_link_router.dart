/// Парсер FCM data-payload'ов в go_router-пути.
///
/// Backend шлёт push с полем `data: { kind, projectId?, stageId?, stepId?,
/// approvalId?, chatId?, paymentId?, requestId?, selfPurchaseId?, ... }` —
/// см. NotificationTemplates и push.processor.ts (ROUTABLE_PAYLOAD_KEYS).
/// Эта утилита преобразует payload в URL. Чистая функция — легко
/// покрывается unit-тестами без Flutter-окружения.
class DeepLinkRouter {
  const DeepLinkRouter._();

  /// Вернуть URL для перехода или `null`, если payload не содержит
  /// распознаваемых полей. Покрывает все типы deep-link'ов из ТЗ §15.2.
  static String? routeFor(Map<String, dynamic> data) {
    String? s(Object? v) => v?.toString();
    final kind = s(data['kind']);
    final approvalId = s(data['approvalId']);
    final paymentId = s(data['paymentId']);
    final chatId = s(data['chatId']);
    // Backend payload использует `requestId` (см. materials.service.ts);
    // `materialId` оставлен как алиас для обратной совместимости.
    final materialRequestId = s(data['requestId'] ?? data['materialId']);
    final selfPurchaseId = s(data['selfPurchaseId']);
    final stepId = s(data['stepId']);
    final stageId = s(data['stageId']);
    final documentId = s(data['documentId']);
    // Backend posts both `jobId` (legacy) и `exportId` (новое).
    final exportId = s(data['exportId'] ?? data['jobId']);
    final projectId = s(data['projectId']);
    final deepLink = s(data['deepLink']);

    // Admin broadcast: deep-link приходит явно, либо открываем ленту уведомлений.
    // Валидируем deepLink — принимаем только относительные пути от корня (`/...`),
    // защита от javascript:/file://schemes и абсолютных URL на сторонние хосты.
    if (kind == 'admin_announcement') {
      if (deepLink != null && deepLink.startsWith('/')) {
        return deepLink;
      }
      return '/notifications';
    }

    // Global-level routes without project context.
    if (paymentId != null) return '/payments/$paymentId';
    if (chatId != null) return '/chats/$chatId';
    if (documentId != null) return '/documents/$documentId';

    if (projectId == null) return null;

    // Export deep-link: открывает список экспортов проекта (отдельная
    // карточка с jobId не нужна — списка достаточно для скачивания).
    if (exportId != null || (kind != null && kind.startsWith('export_'))) {
      return '/projects/$projectId/exports';
    }
    if (approvalId != null) {
      return '/projects/$projectId/approvals/$approvalId';
    }
    if (stepId != null && stageId != null) {
      return '/projects/$projectId/stages/$stageId/steps/$stepId';
    }
    if (stageId != null) {
      return '/projects/$projectId/stages/$stageId';
    }
    if (materialRequestId != null) {
      return '/projects/$projectId/materials/$materialRequestId';
    }
    if (selfPurchaseId != null) {
      return '/projects/$projectId/selfpurchases/$selfPurchaseId';
    }

    // Fallback: open project console.
    return '/projects/$projectId';
  }

  /// Разбор строки «тип уведомления» из backend (NotificationKind) в
  /// удобную категорию — используется в NotificationsScreen для иконок.
  static NotificationRoute categoryOf(String kind) {
    if (kind.startsWith('approval_') || kind == 'stage_rejected_by_customer') {
      return NotificationRoute.approval;
    }
    if (kind.startsWith('payment_')) return NotificationRoute.payment;
    if (kind.startsWith('chat_')) return NotificationRoute.chat;
    if (kind.startsWith('document_')) return NotificationRoute.document;
    if (kind.startsWith('material_') ||
        kind.startsWith('selfpurchase_') ||
        kind.startsWith('tool_')) {
      return NotificationRoute.materials;
    }
    if (kind.startsWith('stage_') ||
        kind.startsWith('step_') ||
        kind == 'note_created_for_me' ||
        kind == 'question_asked') {
      return NotificationRoute.stage;
    }
    if (kind.startsWith('export_')) return NotificationRoute.export;
    if (kind == 'admin_announcement') return NotificationRoute.announcement;
    return NotificationRoute.other;
  }
}

enum NotificationRoute {
  approval,
  payment,
  chat,
  materials,
  stage,
  document,
  export,
  announcement,
  other,
}
