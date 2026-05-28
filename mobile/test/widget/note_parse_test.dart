import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/notes/data/notes_repository.dart';
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

  group('NoteKind', () {
    test('apiValue roundtrip', () {
      for (final k in NoteKind.values) {
        expect(NoteKind.fromString(k.apiValue), k);
      }
    });

    test('null / unknown → text (legacy compatibility)', () {
      expect(NoteKind.fromString(null), NoteKind.text);
      expect(NoteKind.fromString('?'), NoteKind.text);
    });
  });

  group('TranscriptStatus', () {
    test('null/unknown → null (transcription не запрошена / вариант A)', () {
      expect(TranscriptStatus.fromString(null), isNull);
      expect(TranscriptStatus.fromString(''), isNull);
      expect(TranscriptStatus.fromString('whatever'), isNull);
    });

    test('известные значения парсятся', () {
      expect(TranscriptStatus.fromString('pending'), TranscriptStatus.pending);
      expect(TranscriptStatus.fromString('done'), TranscriptStatus.done);
      expect(TranscriptStatus.fromString('failed'), TranscriptStatus.failed);
    });
  });

  group('Note.parse', () {
    test('stage-scoped text-note (legacy payload без kind)', () {
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
      expect(n.kind, NoteKind.text);
      expect(n.audioUrl, isNull);
    });

    test('audio-note с presigned audioUrl (E11 §11.4 вариант A)', () {
      final n = Note.parse({
        'id': 'n2',
        'scope': 'personal',
        'kind': 'audio',
        'authorId': 'u1',
        'projectId': 'p1',
        'audioKey': 'notes/audio/abc.m4a',
        'audioMimeType': 'audio/m4a',
        'audioDurationMs': 12340,
        'audioUrl': 'https://s3/notes/audio/abc.m4a?sig=x',
        'text': null,
        'createdAt': '2026-05-28T08:00:00Z',
        'updatedAt': '2026-05-28T08:00:00Z',
      });
      expect(n.kind, NoteKind.audio);
      expect(n.audioKey, 'notes/audio/abc.m4a');
      expect(n.audioDurationMs, 12340);
      expect(n.audioUrl, contains('notes/audio/abc.m4a'));
      expect(n.text, isNull);
    });

    test('team_broadcast аудио с подписью (caption)', () {
      final n = Note.parse({
        'id': 'n3',
        'scope': 'team_broadcast',
        'kind': 'audio',
        'authorId': 'u1',
        'projectId': 'p1',
        'audioKey': 'notes/audio/x.m4a',
        'audioMimeType': 'audio/m4a',
        'audioDurationMs': 5000,
        'text': 'Послушайте про парковку',
        'createdAt': '2026-05-28T08:00:00Z',
        'updatedAt': '2026-05-28T08:00:00Z',
      });
      expect(n.scope, NoteScope.teamBroadcast);
      expect(n.kind, NoteKind.audio);
      expect(n.text, 'Послушайте про парковку');
    });
  });

  group('NotesListFilter', () {
    test('apiValue корректные', () {
      // Тест дублирует ENUM exhaustiveness — при добавлении нового фильтра
      // (например 'stage') этот блок упадёт и заставит обновить экран.
      expect(NotesListFilter.values.length, 3);
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
