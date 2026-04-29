import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../domain/legal_publication.dart';

class LegalPublicationsRepository {
  LegalPublicationsRepository(this._dio);

  final Dio _dio;

  Future<List<LegalPublication>> listActive() async {
    // Endpoint специально с дефисом: legal/<...> исключён из /api prefix
    // (legal-public stream без авторизации), а listing нужен с авторизацией.
    final r = await _dio.get<List<dynamic>>('/api/legal-publications/list');
    return r.data!
        .map((e) => LegalPublication.parse(e as Map<String, dynamic>))
        .toList();
  }
}

final legalPublicationsRepositoryProvider =
    Provider<LegalPublicationsRepository>(
  (ref) => LegalPublicationsRepository(ref.read(dioProvider)),
);
