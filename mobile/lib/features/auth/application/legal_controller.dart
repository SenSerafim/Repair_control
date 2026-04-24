import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/legal_document.dart';

class LegalPendingState {
  const LegalPendingState({
    required this.pendingKinds,
    this.isLoading = false,
    this.failure,
  });

  final List<LegalKind> pendingKinds;
  final bool isLoading;
  final AuthFailure? failure;

  bool get hasPending => pendingKinds.isNotEmpty;

  LegalPendingState copyWith({
    List<LegalKind>? pendingKinds,
    bool? isLoading,
    AuthFailure? failure,
    bool clearFailure = false,
  }) =>
      LegalPendingState(
        pendingKinds: pendingKinds ?? this.pendingKinds,
        isLoading: isLoading ?? this.isLoading,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

/// Контроллер legal-acceptance. Опрашивает `/me/legal-acceptance` после
/// логина и отслеживает какие документы нужно принять.
final legalControllerProvider =
    NotifierProvider<LegalController, LegalPendingState>(
  LegalController.new,
);

class LegalController extends Notifier<LegalPendingState> {
  @override
  LegalPendingState build() =>
      const LegalPendingState(pendingKinds: []);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final status = await _repo.legalAcceptanceStatus();
      final pending = <LegalKind>[];
      for (final entry in status.entries) {
        if (entry.value.required_ && !entry.value.accepted) {
          final kind = _parseKind(entry.key);
          if (kind != null) pending.add(kind);
        }
      }
      state = LegalPendingState(pendingKinds: pending);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, failure: e.failure);
    }
  }

  Future<void> accept(LegalKind kind) async {
    try {
      await _repo.legalAccept(kind);
      state = state.copyWith(
        pendingKinds:
            state.pendingKinds.where((k) => k != kind).toList(),
      );
    } on AuthException catch (e) {
      state = state.copyWith(failure: e.failure);
    }
  }

  LegalKind? _parseKind(String raw) {
    for (final k in LegalKind.values) {
      if (k.apiValue == raw) return k;
    }
    return null;
  }
}
