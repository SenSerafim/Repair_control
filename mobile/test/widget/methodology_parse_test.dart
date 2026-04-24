import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/methodology/domain/methodology.dart';

void main() {
  group('MethodologySection.parse', () {
    test('с вложенными articles отсортированы по orderIndex', () {
      final s = MethodologySection.parse({
        'id': 'sec1',
        'title': 'Электрика',
        'orderIndex': 0,
        'createdAt': '2026-04-01T00:00:00Z',
        'updatedAt': '2026-04-01T00:00:00Z',
        'articles': [
          {
            'id': 'a3',
            'sectionId': 'sec1',
            'title': 'Третья',
            'orderIndex': 2,
            'version': 1,
          },
          {
            'id': 'a1',
            'sectionId': 'sec1',
            'title': 'Первая',
            'orderIndex': 0,
            'version': 1,
          },
          {
            'id': 'a2',
            'sectionId': 'sec1',
            'title': 'Вторая',
            'orderIndex': 1,
            'version': 1,
          },
        ],
      });
      expect(
        s.articles.map((a) => a.title).toList(),
        ['Первая', 'Вторая', 'Третья'],
      );
    });
  });

  group('MethodologyArticle.parse', () {
    test('с etag и version', () {
      final a = MethodologyArticle.parse({
        'id': 'a1',
        'sectionId': 'sec1',
        'title': 'Шаг 1',
        'body': 'Очень длинный текст статьи.',
        'orderIndex': 0,
        'version': 3,
        'etag': 'abc123',
        'createdAt': '2026-04-01T00:00:00Z',
        'updatedAt': '2026-04-20T00:00:00Z',
      });
      expect(a.version, 3);
      expect(a.etag, 'abc123');
      expect(a.body, contains('длинный'));
    });
  });

  group('MethodologySearchHit.parse', () {
    test('с snippet и rank', () {
      final h = MethodologySearchHit.parse({
        'id': 'a1',
        'sectionId': 'sec1',
        'title': 'Гипсокартон',
        'snippet': 'Монтаж «гипсокартона» на каркас…',
        'rank': 0.85,
      });
      expect(h.title, 'Гипсокартон');
      expect(h.snippet, contains('«гипсокартона»'));
      expect(h.rank, 0.85);
    });
  });
}
