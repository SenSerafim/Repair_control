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

  static Invitation parse(Map<String, dynamic> json) => Invitation(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        phone: json['phone'] as String,
        role: MembershipRole.fromString(json['role'] as String?),
        status: InvitationStatus.fromString(json['status'] as String?),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
