import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_failure.dart';

enum RecoveryStep { enterPhone, enterCode, enterNewPassword, done }

class RecoveryState {
  const RecoveryState({
    this.step = RecoveryStep.enterPhone,
    this.phone = '',
    this.code = '',
    this.resendAvailableAt,
    this.isSubmitting = false,
    this.lastFailure,
  });

  final RecoveryStep step;
  final String phone;
  final String code;
  final DateTime? resendAvailableAt;
  final bool isSubmitting;
  final AuthFailure? lastFailure;

  Duration get resendIn {
    final target = resendAvailableAt;
    if (target == null) return Duration.zero;
    final diff = target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  RecoveryState copyWith({
    RecoveryStep? step,
    String? phone,
    String? code,
    DateTime? resendAvailableAt,
    bool clearResend = false,
    bool? isSubmitting,
    AuthFailure? lastFailure,
    bool clearFailure = false,
  }) {
    return RecoveryState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      code: code ?? this.code,
      resendAvailableAt: clearResend
          ? null
          : (resendAvailableAt ?? this.resendAvailableAt),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }
}

final recoveryControllerProvider =
    NotifierProvider.autoDispose<RecoveryController, RecoveryState>(
  RecoveryController.new,
);

class RecoveryController extends AutoDisposeNotifier<RecoveryState> {
  /// Пауза между запросами кода — должна совпадать с
  /// `RECOVERY_BLOCK_SECONDS` из .env бекенда (default 300).
  static const resendCooldown = Duration(seconds: 60);

  @override
  RecoveryState build() => const RecoveryState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> sendCode(String phone) async {
    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      phone: phone,
    );
    try {
      await _repo.recoverySend(phone: phone);
      state = state.copyWith(
        step: RecoveryStep.enterCode,
        resendAvailableAt: DateTime.now().add(resendCooldown),
        isSubmitting: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: e.failure,
      );
      return false;
    }
  }

  Future<bool> verifyCode(String code) async {
    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      code: code,
    );
    try {
      await _repo.recoveryVerify(phone: state.phone, code: code);
      state = state.copyWith(
        step: RecoveryStep.enterNewPassword,
        isSubmitting: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: e.failure,
      );
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    try {
      await _repo.recoveryReset(
        phone: state.phone,
        code: state.code,
        newPassword: newPassword,
      );
      state = state.copyWith(step: RecoveryStep.done, isSubmitting: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        lastFailure: e.failure,
      );
      return false;
    }
  }

  void reset() {
    state = const RecoveryState();
  }
}
