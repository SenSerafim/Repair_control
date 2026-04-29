import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/push/deep_link_router.dart';

void main() {
  group('DeepLinkRouter.routeFor — push deep-links (ТЗ §15.2)', () {
    test('admin_announcement без deepLink → /notifications', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'admin_announcement',
      });
      expect(route, '/notifications');
    });

    test('admin_announcement с явным deepLink — следуем по нему', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'admin_announcement',
        'deepLink': '/projects/abc',
      });
      expect(route, '/projects/abc');
    });

    test('approval_* (любой scope) → /projects/:id/approvals/:approvalId', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'approval_requested',
        'projectId': 'p-1',
        'approvalId': 'a-1',
        'stageId': 's-1',
      });
      expect(route, '/projects/p-1/approvals/a-1');
    });

    test('plan_approved → approval-detail (через approvalId в payload)', () {
      // Бэк: feed.emit kind='plan_approved' payload={approvalId}.
      final route = DeepLinkRouter.routeFor({
        'kind': 'plan_approved',
        'projectId': 'p-1',
        'approvalId': 'a-plan',
      });
      expect(route, '/projects/p-1/approvals/a-plan');
    });

    test('payment → /payments/:paymentId (root-level)', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'payment_pending',
        'paymentId': 'pay-7',
      });
      expect(route, '/payments/pay-7');
    });

    test('chat → /chats/:chatId (root-level)', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'chat_message',
        'chatId': 'c-3',
      });
      expect(route, '/chats/c-3');
    });

    test('stage без approval → /projects/:id/stages/:stageId', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'stage_started',
        'projectId': 'p-1',
        'stageId': 's-2',
      });
      expect(route, '/projects/p-1/stages/s-2');
    });

    test('step → /projects/:id/stages/:sid/steps/:stid', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'step_completed',
        'projectId': 'p-1',
        'stageId': 's-2',
        'stepId': 'st-9',
      });
      expect(route, '/projects/p-1/stages/s-2/steps/st-9');
    });

    test('document с documentId → /documents/:id', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'document_uploaded',
        'projectId': 'p-1',
        'documentId': 'doc-7',
      });
      expect(route, '/documents/doc-7');
    });

    test('document без documentId — fallback на проект', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'document_uploaded',
        'projectId': 'p-1',
      });
      expect(route, '/projects/p-1');
    });

    test('export_ready (jobId) → /projects/:id/exports', () {
      // Backend шлёт jobId — мы маршрутизируем в список экспортов
      // (один URL на всё, скачивание через downloadUrl в записи).
      final route = DeepLinkRouter.routeFor({
        'kind': 'export_completed',
        'projectId': 'p-1',
        'jobId': 'exp-9',
      });
      expect(route, '/projects/p-1/exports');
    });

    test('export_failed без jobId — всё равно на /exports', () {
      final route = DeepLinkRouter.routeFor({
        'kind': 'export_failed',
        'projectId': 'p-1',
      });
      expect(route, '/projects/p-1/exports');
    });

    test('пустой payload → null', () {
      expect(DeepLinkRouter.routeFor(const {}), isNull);
    });
  });

  group('DeepLinkRouter.categoryOf', () {
    test('approval_* → NotificationRoute.approval', () {
      expect(
        DeepLinkRouter.categoryOf('approval_requested'),
        NotificationRoute.approval,
      );
      expect(
        DeepLinkRouter.categoryOf('approval_approved'),
        NotificationRoute.approval,
      );
      expect(
        DeepLinkRouter.categoryOf('approval_rejected'),
        NotificationRoute.approval,
      );
    });

    test('payment_* → payment', () {
      expect(
        DeepLinkRouter.categoryOf('payment_confirmed'),
        NotificationRoute.payment,
      );
    });

    test('chat_* → chat', () {
      expect(
        DeepLinkRouter.categoryOf('chat_message'),
        NotificationRoute.chat,
      );
    });

    test('stage_/step_ → stage', () {
      expect(
        DeepLinkRouter.categoryOf('stage_started'),
        NotificationRoute.stage,
      );
      expect(
        DeepLinkRouter.categoryOf('step_completed'),
        NotificationRoute.stage,
      );
    });

    test('export_* → export', () {
      expect(
        DeepLinkRouter.categoryOf('export_ready'),
        NotificationRoute.export,
      );
      expect(
        DeepLinkRouter.categoryOf('export_completed'),
        NotificationRoute.export,
      );
    });

    test('document_* → document', () {
      expect(
        DeepLinkRouter.categoryOf('document_uploaded'),
        NotificationRoute.document,
      );
    });

    test('неизвестный kind → other', () {
      expect(
        DeepLinkRouter.categoryOf('something_weird'),
        NotificationRoute.other,
      );
    });
  });
}
