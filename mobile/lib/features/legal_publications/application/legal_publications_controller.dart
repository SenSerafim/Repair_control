import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/legal_publications_repository.dart';
import '../domain/legal_publication.dart';

final legalPublicationsProvider =
    FutureProvider<List<LegalPublication>>((ref) async {
  final repo = ref.read(legalPublicationsRepositoryProvider);
  return repo.listActive();
});
