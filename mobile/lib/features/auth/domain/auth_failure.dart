import '../../../core/error/api_error.dart';

/// Доменная ошибка auth-операций. Маппинг из `ApiError.code` (backend
/// `ErrorCodes` — libs/common/src/errors/domain-errors.ts).
enum AuthFailure {
  /// Неверный логин/пароль.
  invalidCredentials,

  /// Лимит попыток логина/recovery исчерпан.
  blocked,

  /// Телефон уже зарегистрирован.
  phoneInUse,

  /// Токен/сессия невалиден. Нужно перезалогиниться.
  sessionExpired,

  /// Recovery-код неверный.
  recoveryInvalidCode,

  /// Recovery-код истёк.
  recoveryExpired,

  /// Аккаунт забанен.
  banned,

  /// 403 — у роли/пользователя нет права на это действие
  /// (например, заказчик пытается одобрить шаг до бригадира).
  forbidden,

  /// 409 — конфликт состояния (например, попытка действия не из своего FSM-перехода).
  conflict,

  /// 404 — сущности нет / она удалена.
  notFound,

  /// 429 — частые запросы.
  rateLimited,

  /// Нет интернета.
  network,

  /// Сервер недоступен (5xx).
  server,

  /// Валидационная ошибка формы.
  validation,

  /// Всё остальное.
  unknown;

  static AuthFailure fromApiError(ApiError e) {
    return switch (e.code) {
      'auth.invalid_credentials' => AuthFailure.invalidCredentials,
      'auth.login_blocked' => AuthFailure.blocked,
      'auth.recovery_blocked' => AuthFailure.blocked,
      'auth.phone_in_use' => AuthFailure.phoneInUse,
      'auth.token_invalid' ||
      'auth.token_expired' ||
      'auth.session_revoked' =>
        AuthFailure.sessionExpired,
      'auth.recovery_invalid_code' => AuthFailure.recoveryInvalidCode,
      'auth.recovery_expired' => AuthFailure.recoveryExpired,
      'auth.banned' => AuthFailure.banned,
      _ => _fromKind(e.kind),
    };
  }

  static AuthFailure _fromKind(ApiErrorKind kind) => switch (kind) {
        ApiErrorKind.network || ApiErrorKind.timeout => AuthFailure.network,
        ApiErrorKind.server => AuthFailure.server,
        ApiErrorKind.validation => AuthFailure.validation,
        ApiErrorKind.unauthorized => AuthFailure.invalidCredentials,
        ApiErrorKind.forbidden => AuthFailure.forbidden,
        ApiErrorKind.notFound => AuthFailure.notFound,
        ApiErrorKind.conflict => AuthFailure.conflict,
        ApiErrorKind.rateLimited => AuthFailure.rateLimited,
        _ => AuthFailure.unknown,
      };

  /// Строка для UI. EN — задел, сейчас RU.
  String get userMessage => switch (this) {
        AuthFailure.invalidCredentials => 'Неверный телефон или пароль',
        AuthFailure.blocked =>
          'Слишком много попыток. Попробуйте позже.',
        AuthFailure.phoneInUse => 'Этот телефон уже зарегистрирован',
        AuthFailure.sessionExpired =>
          'Сессия истекла. Пожалуйста, войдите заново.',
        AuthFailure.recoveryInvalidCode => 'Неверный код из СМС',
        AuthFailure.recoveryExpired =>
          'Код истёк. Запросите новый.',
        AuthFailure.banned => 'Аккаунт заблокирован. Напишите в поддержку.',
        AuthFailure.forbidden =>
          'У вашей роли нет прав на это действие. Возможно, нужно дождаться '
              'решения заказчика или бригадира.',
        AuthFailure.notFound => 'Объект не найден или был удалён.',
        AuthFailure.conflict =>
          'Действие сейчас недоступно: состояние уже изменилось. '
              'Обновите страницу.',
        AuthFailure.rateLimited => 'Слишком часто. Подождите немного.',
        AuthFailure.network => 'Нет подключения к интернету',
        AuthFailure.server => 'Сервер недоступен. Попробуйте позже.',
        AuthFailure.validation => 'Проверьте правильность заполнения',
        AuthFailure.unknown => 'Что-то пошло не так',
      };
}
