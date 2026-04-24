import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/methodology_repository.dart';
import '../domain/methodology.dart';

final methodologySectionsProvider =
    AsyncNotifierProvider<SectionsController, List<MethodologySection>>(
  SectionsController.new,
);

class SectionsController extends AsyncNotifier<List<MethodologySection>> {
  @override
  Future<List<MethodologySection>> build() {
    return ref.read(methodologyRepositoryProvider).listSections();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(methodologyRepositoryProvider).listSections(),
      );
    } on MethodologyException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final methodologySectionProvider = AsyncNotifierProvider.family<
    SectionController, MethodologySection, String>(
  SectionController.new,
);

class SectionController
    extends FamilyAsyncNotifier<MethodologySection, String> {
  @override
  Future<MethodologySection> build(String sectionId) {
    return ref.read(methodologyRepositoryProvider).getSection(sectionId);
  }
}

final methodologyArticleProvider = AsyncNotifierProvider.family<
    ArticleController, MethodologyArticle, String>(
  ArticleController.new,
);

class ArticleController
    extends FamilyAsyncNotifier<MethodologyArticle, String> {
  @override
  Future<MethodologyArticle> build(String articleId) {
    return ref.read(methodologyRepositoryProvider).getArticle(articleId);
  }
}

final methodologySearchQueryProvider = StateProvider<String>((ref) => '');

final methodologySearchResultsProvider =
    FutureProvider<List<MethodologySearchHit>>((ref) async {
  final query = ref.watch(methodologySearchQueryProvider).trim();
  if (query.length < 2) return const [];
  return ref.read(methodologyRepositoryProvider).search(query);
});
