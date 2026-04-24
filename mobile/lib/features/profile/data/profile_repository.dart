import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/system_role.dart';
import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/faq.dart';
import '../domain/notification_setting.dart';
import '../domain/user_profile.dart';

/// Ошибка Profile-слоя. Переиспользует AuthFailure, т.к. большинство
/// ошибок по профилю — те же кейсы (auth, network, validation).
class ProfileException implements Exception {
  ProfileException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;

  @override
  String toString() => 'ProfileException($failure, $apiError)';
}

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> getMe() =>
      _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/me');
        return UserProfile.parse(r.data!);
      });

  Future<UserProfile> updateMe({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? language,
    String? email,
  }) =>
      _call(() async {
        final body = <String, dynamic>{
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (language != null) 'language': language,
          if (email != null) 'email': email,
        };
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/me',
          data: body,
        );
        return UserProfile.parse(r.data!);
      });

  Future<List<UserRoleEntry>> listRoles() =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>('/api/me/roles');
        return r.data!
            .map((e) => UserRoleEntry.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<List<UserRoleEntry>> addRole(SystemRole role) =>
      _call(() async {
        final r = await _dio.post<List<dynamic>>(
          '/api/me/roles',
          data: {'role': role.name},
        );
        return r.data!
            .map((e) => UserRoleEntry.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<List<UserRoleEntry>> removeRole(SystemRole role) =>
      _call(() async {
        final r =
            await _dio.delete<List<dynamic>>('/api/me/roles/${role.name}');
        return r.data!
            .map((e) => UserRoleEntry.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<void> setActiveRole(SystemRole role) =>
      _call(() async {
        await _dio.put<void>(
          '/api/me/active-role',
          data: {'role': role.name},
        );
      });

  Future<List<NotificationSetting>> listNotificationSettings() =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/me/notification-settings',
        );
        return r.data!
            .map(
              (e) => NotificationSetting.parse(e as Map<String, dynamic>),
            )
            .toList();
      });

  Future<void> patchNotificationSetting({
    required String kind,
    required bool pushEnabled,
  }) =>
      _call(() async {
        await _dio.patch<void>(
          '/api/me/notification-settings',
          data: {'kind': kind, 'pushEnabled': pushEnabled},
        );
      });

  Future<Map<String, String>> getAppSettings() =>
      _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/me/app-settings');
        return r.data!.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      });

  Future<List<FaqSection>> listFaq() =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>('/api/faq');
        return r.data!
            .map((e) => FaqSection.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<void> submitFeedback({
    required String text,
    List<String> attachmentKeys = const [],
  }) =>
      _call(() async {
        await _dio.post<void>(
          '/api/feedback',
          data: {
            'text': text,
            if (attachmentKeys.isNotEmpty) 'attachmentKeys': attachmentKeys,
          },
        );
      });

  /// Presigned upload ответ: { key, url, method, headers, expiresIn }.
  /// Используется для загрузки аватара и вложений.
  Future<PresignedUpload> presignUpload({
    required String originalName,
    required String mimeType,
    required int sizeBytes,
    required String scope,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/files/presign-upload',
          data: {
            'originalName': originalName,
            'mimeType': mimeType,
            'sizeBytes': sizeBytes,
            'scope': scope,
          },
        );
        return PresignedUpload.fromJson(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ProfileException(AuthFailure.fromApiError(api), api);
    }
  }
}

class PresignedUpload {
  PresignedUpload({
    required this.key,
    required this.url,
    required this.method,
    required this.headers,
    required this.expiresIn,
  });

  factory PresignedUpload.fromJson(Map<String, dynamic> json) =>
      PresignedUpload(
        key: json['key'] as String,
        url: json['url'] as String,
        method: json['method'] as String? ?? 'PUT',
        headers: (json['headers'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 300,
      );

  final String key;
  final String url;
  final String method;
  final Map<String, String> headers;
  final int expiresIn;
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  // Переиспользуем Dio из shared-провайдера (с auth interceptor).
  final dio = ref.read(dioProvider);
  return ProfileRepository(dio);
});
