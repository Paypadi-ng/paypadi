import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/models/user_model/user_model.dart';
import 'package:paypadi/core/repositories/authentication/i_authentication_repository.dart';
import 'package:paypadi/core/repositories/profile/i_profile_repository.dart';
import 'package:paypadi/core/repositories/session/i_session_repository.dart';
import 'package:paypadi/core/services/biometrics_service.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/notifications/notifications_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';

import '../helpers/transfer_fakes.dart';

int _secondsFromNow(Duration offset) =>
    DateTime.now().toUtc().add(offset).millisecondsSinceEpoch ~/ 1000;

const _user = UserModel(
  id: 'b7d1c2e4',
  role: 'rider',
  phoneNumber: '08031234567',
  firstName: 'Ada',
  lastName: 'Obi',
  isActive: true,
  phoneVerified: true,
  dateJoined: '2026-10-01T09:00:00Z',
);

class _FakeAuthRepository implements IAuthenticationRepository {
  int logins = 0;

  @override
  FutureResultOf<ApiResponse<LoginResponse>> login(
    Map<String, dynamic> payload,
  ) async {
    logins++;
    return success(
      ok(
        LoginResponse(
          accessToken: 'login-access',
          refreshToken: 'login-refresh',
          accessTokenExpiry: _secondsFromNow(const Duration(hours: 1)),
          refreshTokenExpiry: _secondsFromNow(const Duration(hours: 24)),
          user: _user,
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeSessionRepository implements ISessionRepository {
  _FakeSessionRepository({this.rejected = false});
  final bool rejected;
  int refreshes = 0;

  @override
  FutureApiResultOf<SessionResponse> refreshTokens(String refreshToken) async {
    refreshes++;
    if (rejected) {
      return failure(
        const ServerException.unauthorizedRequest('Token is invalid'),
      );
    }
    return success(ok(const SessionResponse(accessToken: 'renewed-access')));
  }
}

class _FakeProfileRepository implements IProfileRepository {
  final List<Map<String, dynamic>> pins = [];

  @override
  FutureApiResultOf<void> setTransactionPin(
    Map<String, dynamic> payload,
  ) async {
    pins.add(payload);
    return success(ok<void>(null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeBiometrics extends BiometricsService {
  _FakeBiometrics({required this.approves});
  final bool approves;
  int prompts = 0;

  @override
  Future<bool> authenticate([String? reason]) async {
    prompts++;
    return approves;
  }
}

class _FakeNotifications implements INotificationsService {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository auth;
  late RecordingRouter router;
  late SilentToastController toasts;

  /// A device that signed in with an older version: a live session, plus
  /// the password and transaction PIN that version stored.
  void deviceFromOlderVersion() {
    FlutterSecureStorage.setMockInitialValues({
      CacheKeys.accessToken: 'old-access',
      CacheKeys.accessTokenExpiry:
          '${_secondsFromNow(const Duration(hours: 1))}',
      CacheKeys.refreshToken: 'old-refresh',
      CacheKeys.refreshTokenExpiry:
          '${_secondsFromNow(const Duration(hours: 20))}',
      CacheKeys.phoneNumber: '08031234567',
      CacheKeys.legacyPassword: '123456',
      CacheKeys.legacyTransactionPin: '1234',
    });
  }

  ProviderContainer containerWith({
    bool biometricsApprove = true,
    _FakeSessionRepository? session,
    _FakeProfileRepository? profile,
  }) {
    auth = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        authenticationRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(
          session ?? _FakeSessionRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          profile ?? _FakeProfileRepository(),
        ),
        biometricsProvider.overrideWithValue(
          _FakeBiometrics(approves: biometricsApprove),
        ),
        notificationsServiceProvider.overrideWithValue(_FakeNotifications()),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    router = container.read(appRouterProvider) as RecordingRouter;
    toasts =
        container.read(appToastControllerProvider.notifier)
            as SilentToastController;
    // Keep the auto-dispose controllers alive, as their screens do.
    container
      ..listen(authenticationControllerProvider, (_, _) {})
      ..listen(riderProfileProvider, (_, _) {});
    return container;
  }

  Future<String?> stored(ProviderContainer container, String key) =>
      container.read(secureCacheProvider).get<String>(key);

  setUp(deviceFromOlderVersion);

  group('signing in with the password', () {
    test('keeps the session but never stores the password, and deletes '
        'what older versions stored', () async {
      final container = containerWith();

      await container
          .read(authenticationControllerProvider.notifier)
          .login('08031234567', '654321');

      expect(await stored(container, CacheKeys.accessToken), 'login-access');
      expect(await stored(container, CacheKeys.legacyPassword), isNull);
      expect(await stored(container, CacheKeys.legacyTransactionPin), isNull);
      expect(router.pushed.single, isA<DashboardRoute>());
    });
  });

  group('unlocking with biometrics', () {
    test('renews the session with the refresh token instead of replaying a '
        'password', () async {
      final session = _FakeSessionRepository();
      final container = containerWith(session: session);

      await container
          .read(authenticationControllerProvider.notifier)
          .unlockWithBiometrics();

      expect(session.refreshes, 1);
      expect(auth.logins, 0);
      expect(await stored(container, CacheKeys.accessToken), 'renewed-access');
      expect(await stored(container, CacheKeys.legacyPassword), isNull);
      expect(router.pushed.single, isA<DashboardRoute>());
    });

    test('does nothing when the biometric check is declined', () async {
      final session = _FakeSessionRepository();
      final container = containerWith(
        biometricsApprove: false,
        session: session,
      );

      await container
          .read(authenticationControllerProvider.notifier)
          .unlockWithBiometrics();

      expect(session.refreshes, 0);
      expect(router.pushed, isEmpty);
    });

    test('asks for the password when the session has expired', () async {
      final container = containerWith(
        session: _FakeSessionRepository(rejected: true),
      );

      await container
          .read(authenticationControllerProvider.notifier)
          .unlockWithBiometrics();

      expect(router.pushed, isEmpty);
      expect(toasts.errors, [sessionExpiredMessage]);
      expect(container.read(authenticationControllerProvider).isLoading, false);
    });
  });

  group('setting the transaction PIN', () {
    test('sends it to the server without keeping a copy', () async {
      final profile = _FakeProfileRepository();
      final container = containerWith(profile: profile);

      await container
          .read(riderProfileProvider.notifier)
          .setTransactionPin('4321', '4321');
      await Future<void>.delayed(Duration.zero);

      expect(profile.pins.single['new_pin'], '4321');
      expect(await stored(container, CacheKeys.legacyTransactionPin), isNull);
    });
  });
}
