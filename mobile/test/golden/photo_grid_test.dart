import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_photo_grid.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('AppPhotoGrid — empty + add cell', (tester) async {
    await tester.pumpWidget(
      goldenScaffold(
        size: const Size(360, 200),
        child: AppPhotoGrid(imageUrls: const [], onAdd: () {}),
      ),
    );
    await expectLater(
      find.byType(AppPhotoGrid),
      matchesGoldenFile('goldens/photo_grid_empty_with_add.png'),
    );
  });

  testWidgets('AppPhotoGrid — 4 photos + add', (tester) async {
    await tester.pumpWidget(
      goldenScaffold(
        size: const Size(360, 200),
        child: AppPhotoGrid(
          imageUrls: const [
            'https://example.com/1.jpg',
            'https://example.com/2.jpg',
            'https://example.com/3.jpg',
            'https://example.com/4.jpg',
          ],
          onAdd: () {},
        ),
      ),
    );
    await expectLater(
      find.byType(AppPhotoGrid),
      matchesGoldenFile('goldens/photo_grid_4_with_add.png'),
    );
  });

  testWidgets('AppPhotoGrid — 9 photos no-add', (tester) async {
    await tester.pumpWidget(
      goldenScaffold(
        size: const Size(360, 320),
        child: AppPhotoGrid(
          imageUrls: List.generate(
            9,
            (i) => 'https://example.com/${i + 1}.jpg',
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(AppPhotoGrid),
      matchesGoldenFile('goldens/photo_grid_9_no_add.png'),
    );
  });
}
