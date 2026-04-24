import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/push/deep_link_router.dart';
import 'package:repair_control/features/notifications/domain/app_notification.dart';

void main() {
  group('DeepLinkRouter.routeFor', () {
    test('approval: projectId + approvalId', () {
      expect(
        DeepLinkRouter.routeFor({'projectId': 'p1', 'approvalId': 'a1'}),
        '/projects/p1/approvals/a1',
      );
    });

    test('stage + step', () {
      expect(
        DeepLinkRouter.routeFor({
          'projectId': 'p1',
          'stageId': 's1',
          'stepId': 'st1',
        }),
        '/projects/p1/stages/s1/steps/st1',
      );
    });

    test('stage only', () {
      expect(
        DeepLinkRouter.routeFor({'projectId': 'p1', 'stageId': 's1'}),
        '/projects/p1/stages/s1',
      );
    });

    test('material', () {
      expect(
        DeepLinkRouter.routeFor({'projectId': 'p1', 'materialId': 'm1'}),
        '/projects/p1/materials/m1',
      );
    });

    test('payment — глобальный маршрут, даже без projectId', () {
      expect(
        DeepLinkRouter.routeFor({'paymentId': 'pay1'}),
        '/payments/pay1',
      );
    });

    test('chat — глобальный маршрут', () {
      expect(
        DeepLinkRouter.routeFor({'chatId': 'c1'}),
        '/chats/c1',
      );
    });

    test('project fallback', () {
      expect(
        DeepLinkRouter.routeFor({'projectId': 'p1'}),
        '/projects/p1',
      );
    });

    test('пустой payload → null', () {
      expect(DeepLinkRouter.routeFor({}), isNull);
    });

    test('без projectId и известных глобалов → null', () {
      expect(DeepLinkRouter.routeFor({'kind': 'unknown'}), isNull);
    });

    test('числовые id → приводим к строке', () {
      expect(
        DeepLinkRouter.routeFor({'projectId': 42, 'stageId': 7}),
        '/projects/42/stages/7',
      );
    });
  });

  group('DeepLinkRouter.categoryOf', () {
    test('approval_* → approval', () {
      expect(
        DeepLinkRouter.categoryOf('approval_requested'),
        NotificationRoute.approval,
      );
    });

    test('stage_rejected_by_customer → approval (не stage)', () {
      expect(
        DeepLinkRouter.categoryOf('stage_rejected_by_customer'),
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

    test('material_/selfpurchase_/tool_issued → materials', () {
      expect(
        DeepLinkRouter.categoryOf('material_delivered'),
        NotificationRoute.materials,
      );
      expect(
        DeepLinkRouter.categoryOf('selfpurchase_approved'),
        NotificationRoute.materials,
      );
      expect(
        DeepLinkRouter.categoryOf('tool_issued'),
        NotificationRoute.materials,
      );
    });

    test('stage_/step_/note/question → stage', () {
      expect(
        DeepLinkRouter.categoryOf('stage_started'),
        NotificationRoute.stage,
      );
      expect(
        DeepLinkRouter.categoryOf('step_completed'),
        NotificationRoute.stage,
      );
      expect(
        DeepLinkRouter.categoryOf('note_created_for_me'),
        NotificationRoute.stage,
      );
      expect(
        DeepLinkRouter.categoryOf('question_asked'),
        NotificationRoute.stage,
      );
    });

    test('export_* → export', () {
      expect(
        DeepLinkRouter.categoryOf('export_ready'),
        NotificationRoute.export,
      );
    });

    test('unknown kind → other', () {
      expect(
        DeepLinkRouter.categoryOf('random_event'),
        NotificationRoute.other,
      );
    });
  });

  group('AppNotification.fromFcm + extensions', () {
    test('конструирует запись с данными из FCM', () {
      final n = AppNotification.fromFcm(
        id: 'n1',
        kind: 'approval_requested',
        title: 'Согласование',
        body: 'Требуется одобрение',
        data: {'projectId': 'p1', 'approvalId': 'a1'},
      );
      expect(n.id, 'n1');
      expect(n.kind, 'approval_requested');
      expect(n.read, isFalse);
      expect(n.category, NotificationRoute.approval);
      expect(n.routePath, '/projects/p1/approvals/a1');
    });

    test('markAll читаемый — copyWith(read: true)', () {
      final n = AppNotification.fromFcm(
        id: '1',
        kind: 'chat_message',
        title: 't',
        body: 'b',
      );
      expect(n.copyWith(read: true).read, isTrue);
    });
  });
}
