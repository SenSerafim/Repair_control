import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/storage/offline_queue.dart';

/// Phase 8: проверяем что enum OfflineActionKind покрывает все типы из ТЗ §5.3
/// и что serialize/parse работают.
void main() {
  test('OfflineActionKind содержит расширенный набор Phase 8', () {
    // Старые 4 + 5 новых = 9.
    expect(OfflineActionKind.values.length, 9);
    expect(OfflineActionKind.values, contains(OfflineActionKind.stagePause));
    expect(
      OfflineActionKind.values,
      contains(OfflineActionKind.stageResume),
    );
    expect(
      OfflineActionKind.values,
      contains(OfflineActionKind.paymentDispute),
    );
    expect(
      OfflineActionKind.values,
      contains(OfflineActionKind.selfpurchaseCreate),
    );
    expect(
      OfflineActionKind.values,
      contains(OfflineActionKind.materialMarkBought),
    );
  });

  test('OfflineAction roundtrip JSON для нового типа', () {
    final action = OfflineAction(
      id: 'a-1',
      kind: OfflineActionKind.paymentDispute,
      payload: const {
        'paymentId': 'pay-1',
        'reason': 'Сумма не совпадает с актом приёмки',
      },
      createdAt: DateTime.utc(2026, 4, 25, 10),
    );
    final json = action.toJson();
    final back = OfflineAction.fromJson(json);
    expect(back.kind, OfflineActionKind.paymentDispute);
    expect(back.payload['paymentId'], 'pay-1');
    expect(back.payload['reason'], contains('Сумма'));
  });

  test('OfflineAction.fromJson fallback при неизвестном kind', () {
    final back = OfflineAction.fromJson(const {
      'id': 'a-1',
      'kind': 'absolutelyUnknownKind',
      'payload': <String, dynamic>{},
      'createdAt': '2026-04-25T10:00:00Z',
    });
    // Контракт: при unknown kind — fallback на stepToggle (см. реализацию).
    // Это значит что persistent очередь не уронит приложение при апгрейде
    // схемы (читая старый файл с уже несуществующим типом).
    expect(back.kind, OfflineActionKind.stepToggle);
  });
}
