import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/storage/offline_queue.dart';

/// Покрытие enum OfflineActionKind: список типов и базовый roundtrip.
void main() {
  test('OfflineActionKind содержит актуальные типы', () {
    // 2026-05: paymentDispute и materialMarkBought удалены вместе с
    // соответствующими упрощениями домена.
    expect(OfflineActionKind.values.map((k) => k.name).toSet(), {
      'stepToggle',
      'substepToggle',
      'noteCreate',
      'questionAnswer',
      'stagePause',
      'stageResume',
      'selfpurchaseCreate',
    });
  });

  test('OfflineAction roundtrip JSON', () {
    final action = OfflineAction(
      id: 'a-1',
      kind: OfflineActionKind.selfpurchaseCreate,
      payload: const {'projectId': 'p-1', 'amount': 5000_00},
      createdAt: DateTime.utc(2026, 4, 25, 10),
    );
    final json = action.toJson();
    final back = OfflineAction.fromJson(json);
    expect(back.kind, OfflineActionKind.selfpurchaseCreate);
    expect(back.payload['projectId'], 'p-1');
    expect(back.payload['amount'], 5000_00);
  });

  test('OfflineAction.fromJson fallback при неизвестном kind', () {
    final back = OfflineAction.fromJson(const {
      'id': 'a-1',
      'kind': 'absolutelyUnknownKind',
      'payload': <String, dynamic>{},
      'createdAt': '2026-04-25T10:00:00Z',
    });
    // Контракт: при unknown kind — fallback на stepToggle (см. реализацию).
    // Это значит что persistent-очередь не уронит приложение при апгрейде
    // схемы (читая старый файл с уже несуществующим типом).
    expect(back.kind, OfflineActionKind.stepToggle);
  });
}
