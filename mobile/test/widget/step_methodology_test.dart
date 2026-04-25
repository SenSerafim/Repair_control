import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/steps/domain/step.dart';

void main() {
  Map<String, dynamic> base() => {
        'id': 's-1',
        'stageId': 'stage-1',
        'title': 'Test step',
        'orderIndex': 0,
        'type': 'regular',
        'status': 'pending',
        'authorId': 'u-1',
        'createdAt': '2026-04-01T10:00:00Z',
        'updatedAt': '2026-04-01T10:00:00Z',
      };

  test('Step.parse — methodologyArticleId опционален (null fallback)', () {
    final step = Step.parse(base());
    expect(step.methodologyArticleId, isNull);
  });

  test('Step.parse — methodologyArticleId парсится из payload', () {
    final step = Step.parse({
      ...base(),
      'methodologyArticleId': 'art-7',
    });
    expect(step.methodologyArticleId, 'art-7');
  });

  test('Step.copyWith поддерживает methodologyArticleId', () {
    final step = Step.parse(base()).copyWith(
      methodologyArticleId: 'art-9',
    );
    expect(step.methodologyArticleId, 'art-9');
  });
}
