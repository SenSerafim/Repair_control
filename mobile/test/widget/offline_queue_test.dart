import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:repair_control/core/storage/offline_queue.dart';

void main() {
  late Directory tmp;
  late File file;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('oq_');
    file = File('${tmp.path}/queue.json');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  OfflineQueue build() => OfflineQueue(logger: Logger(level: Level.off), file: file);

  test('enqueue сохраняет в файл и переживает перезагрузку', () async {
    final q1 = build();
    await q1.load();
    await q1.enqueue(
      kind: OfflineActionKind.stepToggle,
      payload: {'stepId': 's1', 'complete': true},
    );
    expect(q1.pending.length, 1);

    final q2 = build();
    await q2.load();
    expect(q2.pending.length, 1);
    expect(q2.pending.first.kind, OfflineActionKind.stepToggle);
    expect(q2.pending.first.payload['stepId'], 's1');
  });

  test('drain: handler успех → action удаляется', () async {
    final q = build();
    await q.load();
    final calls = <OfflineAction>[];
    q.registerHandler(OfflineActionKind.noteCreate, (a) async {
      calls.add(a);
    });
    await q.enqueue(
      kind: OfflineActionKind.noteCreate,
      payload: {'text': 'hi'},
    );
    await q.drain();
    expect(calls.length, 1);
    expect(q.pending, isEmpty);
  });

  test('drain: handler падает — action остаётся, attempts++', () async {
    final q = build();
    await q.load();
    q.registerHandler(
      OfflineActionKind.noteCreate,
      (a) async => throw Exception('network'),
    );
    await q.enqueue(
      kind: OfflineActionKind.noteCreate,
      payload: {'text': 'hi'},
    );
    await q.drain();
    expect(q.pending.length, 1);
    expect(q.pending.first.attempts, 1);
  });

  test('drain: 5 неудач подряд → action отбрасывается', () async {
    final q = build();
    await q.load();
    q.registerHandler(
      OfflineActionKind.noteCreate,
      (a) async => throw Exception('network'),
    );
    await q.enqueue(
      kind: OfflineActionKind.noteCreate,
      payload: {'text': 'hi'},
    );
    for (var i = 0; i < 5; i++) {
      await q.drain();
    }
    expect(q.pending, isEmpty);
  });

  test('drain без handler → action удаляется без ошибки', () async {
    final q = build();
    await q.load();
    await q.enqueue(
      kind: OfflineActionKind.questionAnswer,
      payload: {'q': 1},
    );
    await q.drain();
    expect(q.pending, isEmpty);
  });

  test('clear очищает все', () async {
    final q = build();
    await q.load();
    await q.enqueue(
      kind: OfflineActionKind.substepToggle,
      payload: {'id': 'x'},
    );
    await q.clear();
    expect(q.pending, isEmpty);
  });
}
