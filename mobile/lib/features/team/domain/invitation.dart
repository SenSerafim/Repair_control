import 'package:freezed_annotation/freezed_annotation.dart';

import '../../projects/domain/membership.dart';

part 'invitation.freezed.dart';

enum InvitationStatus {
  pending,
  accepted,
  cancelled,
  expired;

  static InvitationStatus fromString(String? raw) {
    if (raw == null) return InvitationStatus.pending;
    for (final s in values) {
      if (s.name.toLowerCase() == raw.toLowerCase()) return s;
    }
    return InvitationStatus.pending;
  }

  String get displayName => switch (this) {
        InvitationStatus.pending => 'Ожидает',
        InvitationStatus.accepted => 'Принято',
        InvitationStatus.cancelled => 'Отменено',
        InvitationStatus.expired => 'Истекло',
      };
}

@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    required String id,
    required String projectId,
    required String phone,
    required MembershipRole role,
    required InvitationStatus status,
    required DateTime expiresAt,
    required DateTime createdAt,
  }) = _Invitation;

  static Invitation parse(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ?? '';
    final token = json['token'] as String?;
    if (id.isNotEmpty && token != null && token.isNotEmpty) {
      InvitationTokens._cache[id] = token;
    }
    return Invitation(
      id: id,
      projectId: (json['projectId'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      role: MembershipRole.fromString(json['role'] as String?),
      status: InvitationStatus.fromString(json['status'] as String?),
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

DateTime _parseDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
  return DateTime.now();
}

/// Side-channel хранилище для invite-токенов: 6-значный код приходит от
/// бэкенда в `token`, но не хранится во freezed-модели (избегаем codegen).
/// Заполняется в `Invitation.parse(...)`; читается через
/// `invitation.token` extension.
class InvitationTokens {
  InvitationTokens._();
  static final Map<String, String> _cache = {};
  static String? of(String invitationId) => _cache[invitationId];
}

extension InvitationTokenExt on Invitation {
  /// 6-значный код приглашения — заполняется при парсинге ответа на
  /// `POST /invitations` или `POST /invitations/generate-code`.
  String? get token => InvitationTokens.of(id);
}
