// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserRoleEntry {
  SystemRole get role => throw _privateConstructorUsedError;
  DateTime get addedAt => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Create a copy of UserRoleEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserRoleEntryCopyWith<UserRoleEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRoleEntryCopyWith<$Res> {
  factory $UserRoleEntryCopyWith(
    UserRoleEntry value,
    $Res Function(UserRoleEntry) then,
  ) = _$UserRoleEntryCopyWithImpl<$Res, UserRoleEntry>;
  @useResult
  $Res call({SystemRole role, DateTime addedAt, bool isActive});
}

/// @nodoc
class _$UserRoleEntryCopyWithImpl<$Res, $Val extends UserRoleEntry>
    implements $UserRoleEntryCopyWith<$Res> {
  _$UserRoleEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserRoleEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? role = null,
    Object? addedAt = null,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as SystemRole,
            addedAt: null == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserRoleEntryImplCopyWith<$Res>
    implements $UserRoleEntryCopyWith<$Res> {
  factory _$$UserRoleEntryImplCopyWith(
    _$UserRoleEntryImpl value,
    $Res Function(_$UserRoleEntryImpl) then,
  ) = __$$UserRoleEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SystemRole role, DateTime addedAt, bool isActive});
}

/// @nodoc
class __$$UserRoleEntryImplCopyWithImpl<$Res>
    extends _$UserRoleEntryCopyWithImpl<$Res, _$UserRoleEntryImpl>
    implements _$$UserRoleEntryImplCopyWith<$Res> {
  __$$UserRoleEntryImplCopyWithImpl(
    _$UserRoleEntryImpl _value,
    $Res Function(_$UserRoleEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserRoleEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? role = null,
    Object? addedAt = null,
    Object? isActive = null,
  }) {
    return _then(
      _$UserRoleEntryImpl(
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as SystemRole,
        addedAt: null == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UserRoleEntryImpl implements _UserRoleEntry {
  const _$UserRoleEntryImpl({
    required this.role,
    required this.addedAt,
    required this.isActive,
  });

  @override
  final SystemRole role;
  @override
  final DateTime addedAt;
  @override
  final bool isActive;

  @override
  String toString() {
    return 'UserRoleEntry(role: $role, addedAt: $addedAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRoleEntryImpl &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @override
  int get hashCode => Object.hash(runtimeType, role, addedAt, isActive);

  /// Create a copy of UserRoleEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRoleEntryImplCopyWith<_$UserRoleEntryImpl> get copyWith =>
      __$$UserRoleEntryImplCopyWithImpl<_$UserRoleEntryImpl>(this, _$identity);
}

abstract class _UserRoleEntry implements UserRoleEntry {
  const factory _UserRoleEntry({
    required final SystemRole role,
    required final DateTime addedAt,
    required final bool isActive,
  }) = _$UserRoleEntryImpl;

  @override
  SystemRole get role;
  @override
  DateTime get addedAt;
  @override
  bool get isActive;

  /// Create a copy of UserRoleEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserRoleEntryImplCopyWith<_$UserRoleEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  SystemRole? get activeRole => throw _privateConstructorUsedError;
  List<UserRoleEntry> get roles => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({
    String id,
    String phone,
    String firstName,
    String lastName,
    String? email,
    String? avatarUrl,
    String language,
    SystemRole? activeRole,
    List<UserRoleEntry> roles,
  });
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = freezed,
    Object? avatarUrl = freezed,
    Object? language = null,
    Object? activeRole = freezed,
    Object? roles = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            language: null == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String,
            activeRole: freezed == activeRole
                ? _value.activeRole
                : activeRole // ignore: cast_nullable_to_non_nullable
                      as SystemRole?,
            roles: null == roles
                ? _value.roles
                : roles // ignore: cast_nullable_to_non_nullable
                      as List<UserRoleEntry>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String phone,
    String firstName,
    String lastName,
    String? email,
    String? avatarUrl,
    String language,
    SystemRole? activeRole,
    List<UserRoleEntry> roles,
  });
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? email = freezed,
    Object? avatarUrl = freezed,
    Object? language = null,
    Object? activeRole = freezed,
    Object? roles = null,
  }) {
    return _then(
      _$UserProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        language: null == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String,
        activeRole: freezed == activeRole
            ? _value.activeRole
            : activeRole // ignore: cast_nullable_to_non_nullable
                  as SystemRole?,
        roles: null == roles
            ? _value._roles
            : roles // ignore: cast_nullable_to_non_nullable
                  as List<UserRoleEntry>,
      ),
    );
  }
}

/// @nodoc

class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.email,
    this.avatarUrl,
    required this.language,
    this.activeRole,
    final List<UserRoleEntry> roles = const <UserRoleEntry>[],
  }) : _roles = roles;

  @override
  final String id;
  @override
  final String phone;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String? email;
  @override
  final String? avatarUrl;
  @override
  final String language;
  @override
  final SystemRole? activeRole;
  final List<UserRoleEntry> _roles;
  @override
  @JsonKey()
  List<UserRoleEntry> get roles {
    if (_roles is EqualUnmodifiableListView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roles);
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, phone: $phone, firstName: $firstName, lastName: $lastName, email: $email, avatarUrl: $avatarUrl, language: $language, activeRole: $activeRole, roles: $roles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.activeRole, activeRole) ||
                other.activeRole == activeRole) &&
            const DeepCollectionEquality().equals(other._roles, _roles));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    phone,
    firstName,
    lastName,
    email,
    avatarUrl,
    language,
    activeRole,
    const DeepCollectionEquality().hash(_roles),
  );

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile({
    required final String id,
    required final String phone,
    required final String firstName,
    required final String lastName,
    final String? email,
    final String? avatarUrl,
    required final String language,
    final SystemRole? activeRole,
    final List<UserRoleEntry> roles,
  }) = _$UserProfileImpl;

  @override
  String get id;
  @override
  String get phone;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  String? get email;
  @override
  String? get avatarUrl;
  @override
  String get language;
  @override
  SystemRole? get activeRole;
  @override
  List<UserRoleEntry> get roles;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
