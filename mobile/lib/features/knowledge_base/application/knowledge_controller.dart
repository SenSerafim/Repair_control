import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/knowledge_repository.dart';
import '../domain/knowledge_article.dart';
import '../domain/knowledge_category.dart';
import '../domain/knowledge_search_hit.dart';

/// Аргументы фильтрации списка категорий.
@immutable
class KnowledgeCategoriesFilter {
  const KnowledgeCategoriesFilter({this.scope, this.moduleSlug});
  final KnowledgeCategoryScope? scope;
  final String? moduleSlug;

  @override
  bool operator ==(Object other) =>
      other is KnowledgeCategoriesFilter &&
      other.scope == scope &&
      other.moduleSlug == moduleSlug;

  @override
  int get hashCode => Object.hash(scope, moduleSlug);
}

final knowledgeCategoriesProvider = FutureProvider.family<
    List<KnowledgeCategory>, KnowledgeCategoriesFilter>((ref, filter) async {
  final repo = ref.read(knowledgeRepositoryProvider);
  return repo.listCategories(
    scope: filter.scope,
    moduleSlug: filter.moduleSlug,
  );
});

final knowledgeCategoryDetailProvider =
    FutureProvider.family<KnowledgeCategoryDetail, String>(
  (ref, id) async => ref.read(knowledgeRepositoryProvider).getCategory(id),
);

final knowledgeArticleProvider =
    FutureProvider.family<KnowledgeArticle, String>(
  (ref, id) async => ref.read(knowledgeRepositoryProvider).getArticle(id),
);

class KnowledgeSearchController
    extends AutoDisposeFamilyAsyncNotifier<List<KnowledgeSearchHit>, String> {
  @override
  Future<List<KnowledgeSearchHit>> build(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    return ref.read(knowledgeRepositoryProvider).search(q);
  }
}

final knowledgeSearchProvider = AutoDisposeAsyncNotifierProvider.family<
    KnowledgeSearchController, List<KnowledgeSearchHit>, String>(
  KnowledgeSearchController.new,
);
