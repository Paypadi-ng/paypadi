import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/services/api_service.dart';
import 'package:paypadi/core/services/storage/cache_service.dart';

/// Holds whichever access token the session currently has.
class _TokenCache implements CacheService {
  String token = 'expired-access';

  @override
  Future<T?> get<T>(String key, [T Function(dynamic raw)? parser]) async =>
      token as T;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Answers 401 to the expired token and 200 to any other.
class _ServerAdapter implements HttpClientAdapter {
  final List<String?> tokensSeen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'] as String?;
    tokensSeen.add(auth);
    final rejected = auth == null || auth.endsWith('expired-access');
    return ResponseBody.fromString(
      rejected ? '{"message":"Token expired"}' : '{"ok":true}',
      rejected ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _TokenCache cache;
  late _ServerAdapter server;
  late int renewals;

  /// A client whose session renewal runs [renew] after counting the call.
  Dio dioWith(Future<bool> Function() renew) {
    cache = _TokenCache();
    server = _ServerAdapter();
    renewals = 0;
    final api = ApiService(
      cacheService: cache,
      baseUrl: 'https://api.test',
      renewSession: () {
        renewals++;
        return renew();
      },
    );
    return api.dio..httpClientAdapter = server;
  }

  test(
    'renews the session once and retries a request rejected with 401',
    () async {
      final dio = dioWith(() async {
        cache.token = 'renewed-access';
        return true;
      });

      final response = await dio.get<dynamic>('/wallets/wallet/');

      expect(response.statusCode, 200);
      expect(renewals, 1);
      expect(server.tokensSeen, [
        'Bearer expired-access',
        'Bearer renewed-access',
      ]);
    },
  );

  test('passes the 401 on when the session cannot be renewed', () async {
    final dio = dioWith(() async => false);

    await expectLater(
      dio.get<dynamic>('/wallets/wallet/'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(renewals, 1);
    expect(server.tokensSeen, hasLength(1));
  });

  test('does not try to renew for public endpoints', () async {
    final dio = dioWith(() async => true);

    await expectLater(
      dio.post<dynamic>('/auth/login/'),
      throwsA(isA<DioException>()),
    );
    expect(renewals, 0);
  });

  test('retries only once if the renewed token is rejected too', () async {
    // Renewal reports success, but the server keeps rejecting the token.
    final dio = dioWith(() async => true);

    await expectLater(
      dio.get<dynamic>('/wallets/wallet/'),
      throwsA(isA<DioException>()),
    );
    expect(renewals, 1);
    expect(server.tokensSeen, hasLength(2));
  });
}
