import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/core/error/api_error.dart';
import 'package:repair_control/core/storage/offline_queue.dart';

void main() {
  group('OfflineConflict — userMessage', () {
    test('без code', () {
      const c = OfflineConflict(
        kind: OfflineActionKind.stepToggle,
        payload: {},
      );
      expect(c.userMessage, 'Сервер изменил состояние, перезагрузите экран');
    });

    test('c code', () {
      const c = OfflineConflict(
        kind: OfflineActionKind.stepToggle,
        payload: {},
        error: ApiError(
          kind: ApiErrorKind.conflict,
          statusCode: 409,
          code: 'stages.invalid_transition',
        ),
      );
      expect(c.userMessage, contains('stages.invalid_transition'));
    });
  });
}
