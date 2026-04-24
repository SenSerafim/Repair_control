import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/chat/domain/chat.dart';
import 'package:repair_control/features/chat/domain/message.dart';
import 'package:repair_control/features/documents/domain/document.dart';
import 'package:repair_control/features/exports/domain/export_job.dart';
import 'package:repair_control/features/feed/domain/feed_event.dart';

void main() {
  group('ChatType', () {
    test('roundtrip', () {
      for (final t in ChatType.values) {
        expect(ChatType.fromString(t.apiValue), t);
      }
    });
    test('unknown → project', () {
      expect(ChatType.fromString(null), ChatType.project);
      expect(ChatType.fromString('?'), ChatType.project);
    });
  });

  group('MessageX.canEdit', () {
    const author = 'u1';
    final now = DateTime.utc(2026, 4, 22, 12);

    Message msg({
      String? authorId,
      DateTime? createdAt,
      DateTime? deletedAt,
    }) =>
        Message(
          id: 'm1',
          chatId: 'c1',
          authorId: authorId ?? author,
          createdAt: createdAt ?? now,
          deletedAt: deletedAt,
        );

    test('автор + свежее → true', () {
      final m = msg(createdAt: now.subtract(const Duration(minutes: 5)));
      expect(m.canEdit(byUserId: author, now: now), isTrue);
    });

    test('не автор → false', () {
      final m = msg(createdAt: now);
      expect(m.canEdit(byUserId: 'other', now: now), isFalse);
    });

    test('старше 15 минут → false', () {
      final m = msg(createdAt: now.subtract(const Duration(minutes: 16)));
      expect(m.canEdit(byUserId: author, now: now), isFalse);
    });

    test('удалено → false', () {
      final m = msg(createdAt: now, deletedAt: now);
      expect(m.canEdit(byUserId: author, now: now), isFalse);
    });

    test('ровно 15 минут — граница', () {
      final m = msg(createdAt: now.subtract(const Duration(minutes: 15)));
      expect(m.canEdit(byUserId: author, now: now), isTrue);
    });
  });

  group('Chat.parse', () {
    test('с participants и unreadCount', () {
      final c = Chat.parse({
        'id': 'c1',
        'type': 'group',
        'projectId': 'p1',
        'title': 'Электрика — команда',
        'visibleToCustomer': false,
        'createdById': 'u1',
        'createdAt': '2026-04-22T10:00:00Z',
        'participants': [
          {
            'userId': 'u1',
            'joinedAt': '2026-04-22T10:00:00Z',
          },
          {
            'userId': 'u2',
            'joinedAt': '2026-04-22T10:05:00Z',
            'leftAt': null,
          },
        ],
        'unreadCount': 3,
      });
      expect(c.type, ChatType.group);
      expect(c.participants.length, 2);
      expect(c.unreadCount, 3);
      expect(c.visibleToCustomer, isFalse);
    });
  });

  group('DocumentCategory', () {
    test('roundtrip всех 7', () {
      for (final c in DocumentCategory.values) {
        expect(DocumentCategory.fromString(c.apiValue), c);
      }
    });

    test('mime helpers', () {
      final pdf = Document.parse({
        'id': 'd1',
        'projectId': 'p1',
        'category': 'contract',
        'title': 'Договор',
        'fileKey': 'k',
        'mimeType': 'application/pdf',
        'sizeBytes': 1024,
        'uploadedBy': 'u1',
        'confirmed': true,
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(pdf.isPdf, isTrue);
      expect(pdf.isImage, isFalse);

      final img = pdf.copyWith(mimeType: 'image/jpeg');
      expect(img.isImage, isTrue);
      expect(img.isPdf, isFalse);
    });
  });

  group('FeedCategory.fromKind', () {
    test('project_*', () {
      expect(FeedCategory.fromKind('project_created'), FeedCategory.project);
    });
    test('stage_*', () {
      expect(FeedCategory.fromKind('stage_started'), FeedCategory.stage);
    });
    test('step_/substep_/photo_/note_/question_ → step', () {
      expect(FeedCategory.fromKind('step_completed'), FeedCategory.step);
      expect(FeedCategory.fromKind('photo_attached'), FeedCategory.step);
      expect(FeedCategory.fromKind('note_created'), FeedCategory.step);
      expect(FeedCategory.fromKind('question_asked'), FeedCategory.step);
      expect(FeedCategory.fromKind('extra_work_requested'),
          FeedCategory.step);
    });
    test('approval_* → approval', () {
      expect(FeedCategory.fromKind('approval_approved'),
          FeedCategory.approval);
      expect(FeedCategory.fromKind('plan_approved'), FeedCategory.approval);
      expect(FeedCategory.fromKind('stage_accepted'), FeedCategory.approval);
    });
    test('payment_/budget_ → finance', () {
      expect(FeedCategory.fromKind('payment_created'), FeedCategory.finance);
      expect(FeedCategory.fromKind('budget_updated'), FeedCategory.finance);
    });
    test('material_ → materials', () {
      expect(FeedCategory.fromKind('material_request_sent'),
          FeedCategory.materials);
    });
    test('chat_ → chat', () {
      expect(FeedCategory.fromKind('chat_message'), FeedCategory.chat);
    });
    test('document_/export_ → documents', () {
      expect(FeedCategory.fromKind('document_uploaded'),
          FeedCategory.documents);
      expect(FeedCategory.fromKind('export_ready'), FeedCategory.documents);
    });
    test('неизвестное → other', () {
      expect(FeedCategory.fromKind('random_event'), FeedCategory.other);
    });
  });

  group('ExportKind / ExportStatus', () {
    test('roundtrip', () {
      for (final k in ExportKind.values) {
        expect(ExportKind.fromString(k.apiValue), k);
      }
      for (final s in ExportStatus.values) {
        expect(ExportStatus.fromString(s.apiValue), s);
      }
    });
  });
}
