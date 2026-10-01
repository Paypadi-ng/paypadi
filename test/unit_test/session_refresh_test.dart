import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/repositories/session/i_session_repository.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/src/shared/controllers/session/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/transfer_fakes.dart';

int _secondsFromNow(Duration offset) =>
    DateTime.now().toUtc().add(offset).millisecondsSinceEpoch ~/ 1000;

String _jwt(int exp) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(json.encode(part))).replaceAll('=', '');

  return '${encode({'alg': 'HS256'})}.${encode({'exp': exp})}.signature';
}

/// Answers every refresh with [result] and counts the calls.
class _FakeSessionRepository implements ISessionRepository {
  _FakeSessionRepository(this.result);
  final Result<ApiResponse<SessionResponse>, Exception> result;
  int calls = 0;

  @override
  FutureApiResultOf<SessionResponse> refreshTokens(String refreshToken) async {
    calls++;
    // A refresh loop would otherwise never end; fail it so the test can
    // report the extra calls instead of hanging.
    if (calls > 3) return failure(const ServerException.noInternetConnection());
    return result;
  }
}

Result<ApiResponse<SessionResponse>, Exception> _refreshed({
  required String access,
  String? refresh,
}) => success(
  ApiResponse(
    status: true,
    message: 'Token refreshed',
    data: SessionResponse(accessToken: access, refreshToken: refresh),
  ),
);

class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Preferences whose writes (including logout's clear) succeed silently.
class _FakePrefs implements SharedPreferencesWithCache {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Lets the refresh that SessionController starts from build() finish.
Future<void> _settle() async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final refreshExpiry = _secondsFromNow(const Duration(hours: 20));

  /// Signed in with a valid refresh token but an access token that expired a
  /// minute ago, so starting the session refreshes straight away.
  void signedInWithExpiredAccessToken() {
    FlutterSecureStorage.setMockInitialValues({
      CacheKeys.accessToken: 'old-access',
      CacheKeys.accessTokenExpiry:
          '${_secondsFromNow(const Duration(minutes: -1))}',
      CacheKeys.refreshToken: 'old-refresh',
      CacheKeys.refreshTokenExpiry: '$refreshExpiry',
    });
  }

  Future<ProviderContainer> startSession(
    _FakeSessionRepository repository,
  ) async {
    final container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        sessionRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesFutureProvider.overrideWith(
          (ref) async => _FakePrefs(),
        ),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.future);
    await _settle();
    return container;
  }

  Future<String?> stored(ProviderContainer container, String key) =>
      container.read(secureCacheProvider).get<String>(key);

  setUp(signedInWithExpiredAccessToken);

  test('SessionResponse parses a refresh body without expiry fields', () {
    final response = ApiResponse<SessionResponse>.fromJson(
      {
        'status': true,
        'message': 'Token refreshed',
        'data': {'access': 'new-access'},
      },
      (json) => SessionResponse.fromJson(json! as Map<String, dynamic>),
    );

    expect(response.data.accessToken, 'new-access');
    expect(response.data.refreshToken, isNull);
  });

  group('refreshing an expired access token', () {
    test('stores the new access token with its expiry read from the JWT, '
        'and keeps the refresh token when it is not rotated', () async {
      final accessExpiry = _secondsFromNow(const Duration(hours: 1));
      final access = _jwt(accessExpiry);
      final repository = _FakeSessionRepository(_refreshed(access: access));

      final container = await startSession(repository);

      expect(await stored(container, CacheKeys.accessToken), access);
      expect(
        await stored(container, CacheKeys.accessTokenExpiry),
        '$accessExpiry',
      );
      expect(await stored(container, CacheKeys.refreshToken), 'old-refresh');
      expect(
        await stored(container, CacheKeys.refreshTokenExpiry),
        '$refreshExpiry',
      );
      // The next refresh is scheduled for later, not run again now.
      expect(repository.calls, 1);
    });

    test('stores a rotated refresh token with its own expiry', () async {
      final newRefreshExpiry = _secondsFromNow(const Duration(hours: 24));
      final newRefresh = _jwt(newRefreshExpiry);
      final repository = _FakeSessionRepository(
        _refreshed(
          access: _jwt(_secondsFromNow(const Duration(hours: 1))),
          refresh: newRefresh,
        ),
      );

      final container = await startSession(repository);

      expect(await stored(container, CacheKeys.refreshToken), newRefresh);
      expect(
        await stored(container, CacheKeys.refreshTokenExpiry),
        '$newRefreshExpiry',
      );
    });

    test('drops the old access expiry when the new one cannot be read, '
        'instead of refreshing in a loop', () async {
      final repository = _FakeSessionRepository(
        _refreshed(access: 'opaque-access'),
      );

      final container = await startSession(repository);

      expect(await stored(container, CacheKeys.accessToken), 'opaque-access');
      expect(await stored(container, CacheKeys.accessTokenExpiry), isNull);
      expect(repository.calls, 1);
    });
  });

  group('when the refresh fails', () {
    test('signs the user out if the refresh token is rejected (401)', () async {
      final repository = _FakeSessionRepository(
        failure(const ServerException.unauthorizedRequest('Token is invalid')),
      );

      final container = await startSession(repository);

      expect(await stored(container, CacheKeys.refreshToken), isNull);
      final router = container.read(appRouterProvider) as RecordingRouter;
      expect(router.replacedStacks.single.single, isA<OnboardingRoute>());
    });

    test('keeps the user signed in on a 400', () async {
      final repository = _FakeSessionRepository(
        failure(const ServerException.badRequest('Validation Error')),
      );

      final container = await startSession(repository);

      expect(await stored(container, CacheKeys.refreshToken), 'old-refresh');
    });

    test('keeps the user signed in when offline', () async {
      final repository = _FakeSessionRepository(
        failure(const ServerException.noInternetConnection()),
      );

      final container = await startSession(repository);

      expect(await stored(container, CacheKeys.refreshToken), 'old-refresh');
    });
  });
}
