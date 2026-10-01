import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:paypadi/core/services/storage/cache_service.dart';
import 'package:paypadi/core/utils/constants.dart' show CacheKeys, debugLogger;
import 'package:talker_dio_logger/talker_dio_logger.dart';

class ApiService {
  ApiService({
    required CacheService cacheService,
    required String baseUrl,
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
