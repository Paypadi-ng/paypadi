import 'dart:async';

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
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/features/transfer/controller/transfer_draft.dart';
import 'package:paypadi/src/shared/controllers/session/session_controller.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/transfer_fakes.dart';

int _secondsFromNow(Duration offset) =>
    DateTime.now().toUtc().add(offset).millisecondsSinceEpoch ~/ 1000;

/// Holds each refresh until the test answers it.
class _PendingSessionRepository implements ISessionRepository {
  final List<Completer<Result<ApiResponse<SessionResponse>, Exception>>>
  requests = [];

  @override
  FutureApiResultOf<SessionResponse> refreshTokens(String refreshToken) {
    final request =
        Completer<Result<ApiResponse<SessionResponse>, Exception>>();
    requests.add(request);
    return request.future;
  }
}

class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakePrefs implements SharedPreferencesWithCache {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PendingSessionRepository sessions;
  late RecordingRouter router;
  late ProviderContainer container;

  setUp(() {
    // A live session whose access token doesn't need refreshing yet, so
    // starting the controller sends nothing on its own.
    FlutterSecureStorage.setMockInitialValues({
      CacheKeys.accessToken: 'access',
      CacheKeys.accessTokenExpiry:
          '${_secondsFromNow(const Duration(hours: 1))}',
      CacheKeys.refreshToken: 'refresh',
      CacheKeys.refreshTokenExpiry:
          '${_secondsFromNow(const Duration(hours: 20))}',
    });
    sessions = _PendingSessionRepository();
    container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        sessionRepositoryProvider.overrideWithValue(sessions),
        sharedPreferencesFutureProvider.overrideWith(
          (ref) async => _FakePrefs(),
        ),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
      ],
    );
    addTearDown(container.dispose);
    router = container.read(appRouterProvider) as RecordingRouter;
  });

  SessionController session() =>
      container.read(sessionControllerProvider.notifier);

  Future<String?> stored(String key) =>
      container.read(secureCacheProvider).get<String>(key);

  group('logout', () {
    test('returns to onboarding even though nothing else is listening, as '
        'when tapped from Settings', () async {
      await session().logout();

      expect(await stored(CacheKeys.refreshToken), isNull);
      expect(router.replacedStacks.single.single, isA<OnboardingRoute>());
    });

    test('forgets everything typed during the session', () async {
      container.read(authenticationPayloadProvider)['password'] = '123456';
      container.read(profilePayloadProvider)['license_plate'] = 'ABC123DE';
      container.read(transferDraftControllerProvider.notifier)
        ..start(amount: '1500')
        ..setPin('1234');

      await session().logout();

      expect(container.read(authenticationPayloadProvider), isEmpty);
      expect(container.read(profilePayloadProvider), isEmpty);
      expect(container.read(transferDraftControllerProvider).pin, isNull);
    });
  });

  group('renewSession', () {
    test(
      'shares one refresh between callers that ask at the same time',
      () async {
        final first = session().renewSession();
        final second = session().renewSession();
        await pumpEventQueue();

        expect(sessions.requests, hasLength(1));

        sessions.requests.single.complete(
          success(ok(const SessionResponse(accessToken: 'renewed'))),
        );
        expect(await Future.wait([first, second]), [true, true]);
        expect(await stored(CacheKeys.accessToken), 'renewed');
      },
    );

    test('starts a new refresh once the previous one has finished', () async {
      final first = session().renewSession();
      await pumpEventQueue();
      sessions.requests.single.complete(
        success(ok(const SessionResponse(accessToken: 'renewed'))),
      );
      await first;

      unawaited(session().renewSession());
      await pumpEventQueue();

      expect(sessions.requests, hasLength(2));
    });

    test('signs the user out when the refresh token is rejected', () async {
      final renewal = session().renewSession();
      await pumpEventQueue();
      sessions.requests.single.complete(
        failure(const ServerException.unauthorizedRequest('Token is invalid')),
      );

      expect(await renewal, isFalse);
      await pumpEventQueue();
      expect(router.replacedStacks.single.single, isA<OnboardingRoute>());
    });
  });
}
