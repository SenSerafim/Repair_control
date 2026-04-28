import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../domain/faq.dart';

final faqProvider =
    AsyncNotifierProvider<FaqController, List<FaqSection>>(
  FaqController.new,
);

class FaqController extends AsyncNotifier<List<FaqSection>> {
  @override
  Future<List<FaqSection>> build() async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.listFaq();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await ref.read(profileRepositoryProvider).listFaq());
    } on ProfileException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Загрузка одной статьи FAQ по id (Cluster A: «Статья FAQ»).
final faqItemProvider = FutureProvider.family<FaqItem, String>((ref, id) {
  return ref.read(profileRepositoryProvider).getFaqItem(id);
});
