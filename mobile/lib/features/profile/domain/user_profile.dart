import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/access/system_role.dart';

part 'user_profile.freezed.dart';

/// Роль пользователя (элемент /me/roles).
@freezed
class UserRoleEntry with _$UserRoleEntry {
  const factory UserRoleEntry({
    required SystemRole role,
    required DateTime addedAt,
    required bool isActive,
  }) = _UserRoleEntry;

  static UserRoleEntry parse(Map<String, dynamic> json) => UserRoleEntry(
        role: SystemRole.fromString(json['role'] as String?) ??
            SystemRole.master,
        addedAt: DateTime.parse(json['addedAt'] as String),
        isActive: json['isActive'] as bool? ?? false,
      );
}

/// Профиль текущего пользователя. Соответствует GET /api/me.
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String phone,
    required String firstName,
    required String lastName,
    String? email,
    String? avatarUrl,
    required String language,
    SystemRole? activeRole,
    @Default(<UserRoleEntry>[]) List<UserRoleEntry> roles,
  }) = _UserProfile;

  static UserProfile parse(Map<String, dynamic> json) {
    final rolesRaw = json['roles'] as List<dynamic>? ?? const [];
    // Defensive parsing: при неожиданном ответе сервера (например, body
    // ошибки 401/500 пробившийся через transport, или неполный объект)
    // не падаем с TypeError, а возвращаем пустой профиль — controller
    // потом расценивает это как logout-сигнал.
    return UserProfile(
      id: (json['id'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      language: (json['language'] as String?) ?? 'ru',
      activeRole: SystemRole.fromString(json['activeRole'] as String?),
      roles: rolesRaw
          .whereType<Map<String, dynamic>>()
          .map(UserRoleEntry.parse)
          .toList(),
    );
  }
}

extension UserProfileX on UserProfile {
  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    String first(String s) => s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
    return '${first(firstName)}${first(lastName)}';
  }
}
