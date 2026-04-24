import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/stages/domain/template.dart';

void main() {
  group('TemplateKind.fromString', () {
    test('user', () {
      expect(TemplateKind.fromString('user'), TemplateKind.user);
    });
    test('platform и неизвестное → platform', () {
      expect(TemplateKind.fromString('platform'), TemplateKind.platform);
      expect(TemplateKind.fromString(null), TemplateKind.platform);
      expect(TemplateKind.fromString('?'), TemplateKind.platform);
    });
  });

  group('StageTemplate.parse', () {
    test('платформенный с 3 шагами отсортированы по orderIndex', () {
      final t = StageTemplate.parse({
        'id': 't1',
        'kind': 'platform',
        'title': 'Электрика',
        'description': 'Разводка...',
        'steps': [
          {'id': 'a', 'title': 'C', 'orderIndex': 2},
          {'id': 'b', 'title': 'A', 'orderIndex': 0},
          {'id': 'c', 'title': 'B', 'orderIndex': 1},
        ],
      });
      expect(t.kind, TemplateKind.platform);
      expect(t.steps.map((s) => s.title).toList(), ['A', 'B', 'C']);
    });

    test('минимальный без steps', () {
      final t = StageTemplate.parse({
        'id': 't1',
        'kind': 'user',
        'title': 'Мой шаблон',
      });
      expect(t.steps, isEmpty);
      expect(t.description, isNull);
    });
  });
}
