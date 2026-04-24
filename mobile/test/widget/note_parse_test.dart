import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/notes/domain/note.dart';
import 'package:repair_control/features/steps/domain/question.dart';
import 'package:repair_control/features/steps/domain/substep.dart';

void main() {
  group('NoteScope', () {
    test('apiValue roundtrip', () {
      for (final s in NoteScope.values) {
        expect(NoteScope.fromString(s.apiValue), s);
      }
    });

    test('unknown → personal', () {
      expect(NoteScope.fromString(null), NoteScope.personal);
      expect(NoteScope.fromString('?'), NoteScope.personal);
    });
  });

  group('Note.parse', () {
    test('stage-scoped note', () {
      final n = Note.parse({
        'id': 'n1',
        'scope': 'stage',
        'authorId': 'u1',
        'stageId': 'st1',
        'projectId': 'p1',
        'text': 'Проверить перед штукатуркой',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(n.scope, NoteScope.stage);
      expect(n.stageId, 'st1');
    });
  });

  group('Substep.parse + Question.parse', () {
    test('Substep done', () {
      final s = Substep.parse({
        'id': 'sub1',
        'stepId': 'step1',
        'text': 'Натянуть плёнку',
        'authorId': 'u1',
        'isDone': true,
        'doneAt': '2026-04-22T11:00:00Z',
        'doneById': 'u1',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T11:00:00Z',
      });
      expect(s.isDone, isTrue);
      expect(s.doneAt, isNotNull);
    });

    test('Question answered', () {
      final q = Question.parse({
        'id': 'q1',
        'stepId': 'step1',
        'authorId': 'u1',
        'addresseeId': 'u2',
        'text': 'Какой размер плитки?',
        'status': 'answered',
        'answer': '60×60',
        'answeredAt': '2026-04-22T11:00:00Z',
        'answeredBy': 'u2',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T11:00:00Z',
      });
      expect(q.status, QuestionStatus.answered);
      expect(q.answer, '60×60');
    });
  });
}
