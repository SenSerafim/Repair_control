// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProjectMemberUser {
  String get id => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Create a copy of ProjectMemberUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectMemberUserCopyWith<ProjectMemberUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectMemberUserCopyWith<$Res> {
  factory $ProjectMemberUserCopyWith(
    ProjectMemberUser value,
    $Res Function(ProjectMemberUser) then,
  ) = _$ProjectMemberUserCopyWithImpl<$Res, ProjectMemberUser>;
  @useResult
  $Res call({
    String id,
    String firstName,
    String lastName,
    String phone,
    String? avatarUrl,
  });
}

/// @nodoc
class _$ProjectMemberUserCopyWithImpl<$Res, $Val extends ProjectMemberUser>
    implements $ProjectMemberUserCopyWith<$Res> {
  _$ProjectMemberUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectMemberUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? phone = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProjectMemberUserImplCopyWith<$Res>
    implements $ProjectMemberUserCopyWith<$Res> {
  factory _$$ProjectMemberUserImplCopyWith(
    _$ProjectMemberUserImpl value,
    $Res Function(_$ProjectMemberUserImpl) then,
  ) = __$$ProjectMemberUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String firstName,
    String lastName,
    String phone,
    String? avatarUrl,
  });
}

/// @nodoc
class __$$ProjectMemberUserImplCopyWithImpl<$Res>
    extends _$ProjectMemberUserCopyWithImpl<$Res, _$ProjectMemberUserImpl>
    implements _$$ProjectMemberUserImplCopyWith<$Res> {
  __$$ProjectMemberUserImplCopyWithImpl(
    _$ProjectMemberUserImpl _value,
    $Res Function(_$ProjectMemberUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProjectMemberUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? phone = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(
      _$ProjectMemberUserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ProjectMemberUserImpl implements _ProjectMemberUser {
  const _$ProjectMemberUserImpl({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.avatarUrl,
  });

  @override
  final String id;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String phone;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'ProjectMemberUser(id: $id, firstName: $firstName, lastName: $lastName, phone: $phone, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectMemberUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, firstName, lastName, phone, avatarUrl);

  /// Create a copy of ProjectMemberUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectMemberUserImplCopyWith<_$ProjectMemberUserImpl> get copyWith =>
      __$$ProjectMemberUserImplCopyWithImpl<_$ProjectMemberUserImpl>(
        this,
        _$identity,
      );
}

abstract class _ProjectMemberUser implements ProjectMemberUser {
  const factory _ProjectMemberUser({
    required final String id,
    required final String firstName,
    required final String lastName,
    required final String phone,
    final String? avatarUrl,
  }) = _$ProjectMemberUserImpl;

  @override
  String get id;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  String get phone;
  @override
  String? get avatarUrl;

  /// Create a copy of ProjectMemberUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectMemberUserImplCopyWith<_$ProjectMemberUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Membership {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  MembershipRole get role => throw _privateConstructorUsedError;
  DateTime get addedAt => throw _privateConstructorUsedError;
  ProjectMemberUser? get user => throw _privateConstructorUsedError;

  /// Create a copy of Membership
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MembershipCopyWith<Membership> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MembershipCopyWith<$Res> {
  factory $MembershipCopyWith(
    Membership value,
    $Res Function(Membership) then,
  ) = _$MembershipCopyWithImpl<$Res, Membership>;
  @useResult
  $Res call({
    String id,
    String projectId,
    String userId,
    MembershipRole role,
    DateTime addedAt,
    ProjectMemberUser? user,
  });

  $ProjectMemberUserCopyWith<$Res>? get user;
}

/// @nodoc
class _$MembershipCopyWithImpl<$Res, $Val extends Membership>
    implements $MembershipCopyWith<$Res> {
  _$MembershipCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Membership
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? userId = null,
    Object? role = null,
    Object? addedAt = null,
    Object? user = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as MembershipRole,
            addedAt: null == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            user: freezed == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as ProjectMemberUser?,
          )
          as $Val,
    );
  }

  /// Create a copy of Membership
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectMemberUserCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $ProjectMemberUserCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MembershipImplCopyWith<$Res>
    implements $MembershipCopyWith<$Res> {
  factory _$$MembershipImplCopyWith(
    _$MembershipImpl value,
    $Res Function(_$MembershipImpl) then,
  ) = __$$MembershipImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    String userId,
    MembershipRole role,
    DateTime addedAt,
    ProjectMemberUser? user,
  });

  @override
  $ProjectMemberUserCopyWith<$Res>? get user;
}

/// @nodoc
class __$$MembershipImplCopyWithImpl<$Res>
    extends _$MembershipCopyWithImpl<$Res, _$MembershipImpl>
    implements _$$MembershipImplCopyWith<$Res> {
  __$$MembershipImplCopyWithImpl(
    _$MembershipImpl _value,
    $Res Function(_$MembershipImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Membership
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? userId = null,
    Object? role = null,
    Object? addedAt = null,
    Object? user = freezed,
  }) {
    return _then(
      _$MembershipImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as MembershipRole,
        addedAt: null == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        user: freezed == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as ProjectMemberUser?,
      ),
    );
  }
}

/// @nodoc

class _$MembershipImpl implements _Membership {
  const _$MembershipImpl({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    required this.addedAt,
    this.user,
  });

  @override
  final String id;
  @override
  final String projectId;
  @override
  final String userId;
  @override
  final MembershipRole role;
  @override
  final DateTime addedAt;
  @override
  final ProjectMemberUser? user;

  @override
  String toString() {
    return 'Membership(id: $id, projectId: $projectId, userId: $userId, role: $role, addedAt: $addedAt, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MembershipImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt) &&
            (identical(other.user, user) || other.user == user));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, projectId, userId, role, addedAt, user);

  /// Create a copy of Membership
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MembershipImplCopyWith<_$MembershipImpl> get copyWith =>
      __$$MembershipImplCopyWithImpl<_$MembershipImpl>(this, _$identity);
}

abstract class _Membership implements Membership {
  const factory _Membership({
    required final String id,
    required final String projectId,
    required final String userId,
    required final MembershipRole role,
    required final DateTime addedAt,
    final ProjectMemberUser? user,
  }) = _$MembershipImpl;

  @override
  String get id;
  @override
  String get projectId;
  @override
  String get userId;
  @override
  MembershipRole get role;
  @override
  DateTime get addedAt;
  @override
  ProjectMemberUser? get user;

  /// Create a copy of Membership
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MembershipImplCopyWith<_$MembershipImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
