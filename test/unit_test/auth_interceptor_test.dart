import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/services/api_service.dart';
import 'package:paypadi/core/services/storage/cache_service.dart';

/// A cache that always holds an access token.
class _TokenCache implements CacheService {
  @override
  Future<T?> get<T>(String key, [T Function(dynamic raw)? parser]) async =>
      'stored-access-token' as T;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Records each request instead of sending it.
class _CapturingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _CapturingAdapter adapter;

  setUp(() {
    adapter = _CapturingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthenticationInterceptor(secureCache: _TokenCache()));
  });

  Future<String?> authorizationFor(String path) async {
    await dio.post<void>(path);
    return adapter.requests.last.headers['Authorization'] as String?;
  }

  test('does not send the stored access token when refreshing it', () async {
    expect(await authorizationFor('/auth/jwt/token/refresh/'), isNull);
  });

  test('does not send a token to the other public auth endpoints', () async {
    for (final path in [
      '/auth/login/',
      '/auth/register/',
      '/auth/otp/request/',
      '/auth/otp/verify/',
    ]) {
      expect(await authorizationFor(path), isNull, reason: path);
    }
  });

  test('sends the stored access token to protected endpoints', () async {
    expect(
      await authorizationFor('/wallets/wallet/'),
      'Bearer stored-access-token',
    );
  });
}
