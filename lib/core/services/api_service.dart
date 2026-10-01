import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:paypadi/core/services/storage/cache_service.dart';
import 'package:paypadi/core/utils/constants.dart' show CacheKeys, debugLogger;
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

class ApiService {
  ApiService({
    required CacheService cacheService,
    required String baseUrl,
    Future<bool> Function()? renewSession,
  }) {
    dio =
        Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          )
          ..interceptors.addAll(
            [
              AuthenticationInterceptor(secureCache: cacheService),
              if (renewSession != null)
                SessionRenewalInterceptor(
                  retry: (options) => dio.fetch<dynamic>(options),
                  renewSession: renewSession,
                ),
              if (kDebugMode)
                TalkerDioLogger(
                  talker: debugLogger,
                  settings: const TalkerDioLoggerSettings(
                    printRequestHeaders: true,
                    printResponseHeaders: true,
                  ),
                ),
            ],
          );

    dio.addSentry(
      failedRequestStatusCodes: [
        SentryStatusCode.range(400, 404),
        SentryStatusCode(500),
      ],
    );
  }

  late final Dio dio;
}

class AuthenticationInterceptor extends Interceptor {
  AuthenticationInterceptor({required CacheService secureCache})
    : _cache = secureCache;
  final CacheService _cache;

  /// Endpoints called without a session, so no (possibly expired) access
  /// token is attached. The refresh endpoint carries its refresh token in
  /// the body.
  static const Set<String> _publicPaths = {
    '/auth/login/',
    '/auth/register/',
    '/auth/otp/request/',
    '/auth/otp/verify/',
    '/auth/jwt/token/refresh/',
  };

  /// Whether [path] is called without a session.
  static bool isPublicPath(String path) => _publicPaths.contains(path);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (!_publicPaths.contains(options.path)) {
        final String? token = await _cache.get<String>(CacheKeys.accessToken);

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e, st) {
      debugLogger.error('AuthInterceptor: failed to attach token', e, st);
    } finally {
      handler.next(options);
    }
  }
}

/// Renews the session once when a request is rejected with 401 because the
/// access token expired, then retries the request.
///
/// The retry goes back through [AuthenticationInterceptor], which attaches
/// the renewed token. Public endpoints and requests that were already
/// retried are passed through as they are, so a 401 can't loop.
class SessionRenewalInterceptor extends Interceptor {
  SessionRenewalInterceptor({
    required Future<Response<dynamic>> Function(RequestOptions options) retry,
    required Future<bool> Function() renewSession,
  }) : _retry = retry,
       _renewSession = renewSession;

  final Future<Response<dynamic>> Function(RequestOptions options) _retry;
  final Future<bool> Function() _renewSession;

  static const String _retriedKey = 'session_renewal_retried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final bool canRenew =
        err.response?.statusCode == 401 &&
        !AuthenticationInterceptor.isPublicPath(options.path) &&
        options.extra[_retriedKey] != true;

    if (!canRenew || !await _renewSession()) {
      handler.next(err);
      return;
    }

    try {
      final response = await _retry(
        options.copyWith(extra: {...options.extra, _retriedKey: true}),
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
