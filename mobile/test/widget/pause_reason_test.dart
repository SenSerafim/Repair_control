import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/stages/domain/pause_reason.dart';

void main() {
  group('PauseReason.apiValue', () {
    test('все 4 значения', () {
      expect(PauseReason.materials.apiValue, 'materials');
      expect(PauseReason.approval.apiValue, 'approval');
      expect(PauseReason.forceMajeure.apiValue, 'force_majeure');
      expect(PauseReason.other.apiValue, 'other');
    });
  });

  group('PauseReason.fromApiValue', () {
    test('roundtrip всех значений', () {
      for (final r in PauseReason.values) {
        expect(PauseReason.fromApiValue(r.apiValue), r);
      }
    });

    test('null и unknown → other', () {
      expect(PauseReason.fromApiValue(null), PauseReason.other);
      expect(PauseReason.fromApiValue('nope'), PauseReason.other);
    });
  });
}
