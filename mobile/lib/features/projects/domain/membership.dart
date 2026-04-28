import 'package:freezed_annotation/freezed_annotation.dart';

part 'membership.freezed.dart';

/// Роль участника внутри проекта.
/// ⚠ Отличается от SystemRole: глобальный `contractor` = membership `foreman`.
enum MembershipRole {
  customer,
  representative,
  foreman,
  master;

  static MembershipRole fromString(String? raw) {
    if (raw == null) return MembershipRole.master;
    for (final r in values) {
      if (r.name.toLowerCase() == raw.toLowerCase()) return r;
    }
    return MembershipRole.master;
  }

  String get displayName => switch (this) {
        MembershipRole.customer => 'Заказчик',
        MembershipRole.representative => 'Представитель',
        MembershipRole.foreman => 'Бригадир',
        MembershipRole.master => 'Мастер',
      };
}

@freezed
class ProjectMemberUser with _$ProjectMemberUser {
  const factory ProjectMemberUser({
    required String id,
    required String firstName,
    required String lastName,
    required String phone,
    String? avatarUrl,
  }) = _ProjectMemberUser;

  static ProjectMemberUser parse(Map<String, dynamic> json) =>
      ProjectMemberUser(
        id: json['id'] as String,
        firstName: (json['firstName'] as String?) ?? '',
        lastName: (json['lastName'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        avatarUrl: json['avatarUrl'] as String?,
      );
}

@freezed
class Membership with _$Membership {
  const factory Membership({
    required String id,
    required String projectId,
    required String userId,
    required MembershipRole role,
    required DateTime addedAt,
    ProjectMemberUser? user,
  }) = _Membership;

  static Membership parse(Map<String, dynamic> json) {
    // Бекенд отдаёт createdAt, мобильное поле исторически называется addedAt;
    // принимаем оба варианта + fallback на now() при отсутствии (избегаем
    // ParallelWaitError: type 'Null' is not a subtype of type 'String').
    final m = Membership(
      id: (json['id'] as String?) ?? '',
      projectId: (json['projectId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      role: MembershipRole.fromString(json['role'] as String?),
      addedAt: _parseMembershipDate(json['addedAt'] ?? json['createdAt']),
      user: json['user'] is Map<String, dynamic>
          ? ProjectMemberUser.parse(json['user'] as Map<String, dynamic>)
          : null,
    );
    final rights = _parseRights(
      json['representativeRights'] ?? json['permissions'],
    );
    if (rights.isNotEmpty) {
      MembershipRights._cache[m.id] = rights;
    }
    return m;
  }
}

DateTime _parseMembershipDate(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
  return DateTime.now();
}

List<String> _parseRights(Object? raw) {
  // Бекенд возвращает RepresentativeRights как объект с булевыми флагами
  // (`{canApprove: true, canSeeBudget: true, ...}`). Старый формат — массив
  // строк — оставлен для обратной совместимости.
  if (raw is Map) {
    final result = <String>[];
    raw.forEach((k, v) {
      if (v == true) result.add(k.toString());
    });
    return List.unmodifiable(result);
  }
  if (raw is List) {
    return raw.map((e) => e.toString()).toList(growable: false);
  }
  return const <String>[];
}

/// Side-channel хранилище `representativeRights` без модификации
/// freezed-generated `Membership` (json-поле приходит с бэка отдельно
/// от основной модели — экспонируется через extension).
///
/// Заполняется в `Membership.parse(...)`; читается через
/// `membership.representativeRights` extension.
class MembershipRights {
  MembershipRights._();
  static final Map<String, List<String>> _cache = {};
  static List<String> of(String membershipId) =>
      _cache[membershipId] ?? const <String>[];
}

extension MembershipRightsExt on Membership {
  List<String> get representativeRights => MembershipRights.of(id);
}
