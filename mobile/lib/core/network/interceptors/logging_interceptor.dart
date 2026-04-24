import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLoggingInterceptor extends Interceptor {
  AppLoggingInterceptor(this._logger);

  final Logger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _logger.d('→ ${options.method} ${options.uri}');
    Sentry.addBreadcrumb(Breadcrumb.http(
      url: options.uri,
      method: options.method,
      level: SentryLevel.info,
    ));
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.d(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
    );
    Sentry.addBreadcrumb(Breadcrumb.http(
      url: response.requestOptions.uri,
      method: response.requestOptions.method,
      statusCode: response.statusCode,
      level: SentryLevel.info,
    ));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _logger.w(
      '✗ ${status ?? '-'} '
      '${err.requestOptions.method} ${err.requestOptions.uri} '
      '| ${err.type.name}',
    );
    Sentry.addBreadcrumb(Breadcrumb.http(
      url: err.requestOptions.uri,
      method: err.requestOptions.method,
      statusCode: status,
      reason: err.type.name,
      level: status != null && status >= 500
          ? SentryLevel.error
          : SentryLevel.warning,
    ));
    // 5xx — отправляем в Sentry как exception.
    if (status != null && status >= 500) {
      Sentry.captureException(err, stackTrace: err.stackTrace);
    }
    handler.next(err);
  }
}
