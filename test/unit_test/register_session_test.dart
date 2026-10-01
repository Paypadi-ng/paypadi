import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/repositories/authentication/i_authentication_repository.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';

const _accessExp = 1767225600;
const _refreshExp = 1767312000;

String _jwt(Map<String, dynamic> claims) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(json.encode(part))).replaceAll('=', '');

  return '${encode({'alg': 'HS256'})}.${encode(claims)}.signature';
}

/// The register body as the backend returns it: no `access_expires` or
/// `refresh_expires`.
Map<String, Object?> _registerBody({
  required String access,
  required String refresh,
}) => {
  'status': true,
  'message': 'Account created',
  'data': {
    'access': access,
    'refresh': refresh,
    'user': {
      'id': 'b7d1c2e4',
      'role': 'rider',
      'phone_number': '+2348031234567',
      'first_name': 'Ada',
      'last_name': 'Obi',
      'is_active': true,
      'verified_phone': true,
      'date_joined': '2026-10-01T09:00:00Z',
    },
  },
};

ApiResponse<RegisterResponse> _parse(Map<String, Object?> body) =>
    ApiResponse<RegisterResponse>.fromJson(
      body,
      (json) => RegisterResponse.fromJson(json! as Map<String, dynamic>),
    );

class _FakeAuthRepository implements IAuthenticationRepository {
  _FakeAuthRepository(this.registerBody);
  final Map<String, Object?> registerBody;

  @override
  FutureApiResultOf<RegisterResponse> createAccount(
    Map<String, dynamic> payload,
  ) => Result.fromAsync(() async => _parse(registerBody));

  @override
  FutureResultOf<ApiResponse<LoginResponse>> login(
    Map<String, dynamic> payload,
  ) => throw UnimplementedError();

  @override
  FutureApiResultOf<RequestOtpResponse> requestForOtpCode(
    Map<String, dynamic> payload,
  ) => throw UnimplementedError();

  @override
  FutureApiResultOf<VerifyOtpResponse> verifyOtpCode(
    Map<String, dynamic> payload,
  ) => throw UnimplementedError();
}

class _RecordingRouter extends AppRouter {
  _RecordingRouter({required super.ref});
  final List<PageRouteInfo> pushed = [];

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushed.add(route);
    return null;
  }
}

/// Swallows every monitoring call; nothing here is about monitoring.
class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterResponse', () {
    test('parses a register body that has no expiry fields', () {
      final response = _parse(_registerBody(access: 'a', refresh: 'r'));

      expect(response.data.accessToken, 'a');
      expect(response.data.refreshToken, 'r');
      expect(response.data.user.firstName, 'Ada');
    });
  });

  group('AuthenticationController.register', () {
    late _RecordingRouter router;

    ProviderContainer containerFor(Map<String, Object?> body) {
      final container = ProviderContainer(
        overrides: [
          monitoringProvider.overrideWithValue(_NoopMonitoring()),
          authenticationRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(body),
          ),
          appRouterProvider.overrideWith(
            (ref) => router = _RecordingRouter(ref: ref),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Keep the auto-dispose controller alive, as the screen's listener does.
      container.listen(authenticationControllerProvider, (_, _) {});
      return container;
    }

    Future<String?> stored(ProviderContainer container, String key) =>
        container.read(secureCacheProvider).get<String>(key);

    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('saves the session with expiries read from the JWTs and moves on '
        'to the transaction PIN screen', () async {
      final access = _jwt({'exp': _accessExp});
      final refresh = _jwt({'exp': _refreshExp});
      final container = containerFor(
        _registerBody(access: access, refresh: refresh),
      );

      await container
          .read(authenticationControllerProvider.notifier)
          .register();

      expect(await stored(container, CacheKeys.accessToken), access);
      expect(await stored(container, CacheKeys.refreshToken), refresh);
      expect(
        await stored(container, CacheKeys.accessTokenExpiry),
        '$_accessExp',
      );
      expect(
        await stored(container, CacheKeys.refreshTokenExpiry),
        '$_refreshExp',
      );
      expect(router.pushed.single, isA<CreateTransactionPinRoute>());
    });

    test('still moves on when the tokens carry no readable expiry', () async {
      final container = containerFor(
        _registerBody(access: 'opaque-access', refresh: 'opaque-refresh'),
      );

      await container
          .read(authenticationControllerProvider.notifier)
          .register();

      expect(await stored(container, CacheKeys.accessToken), 'opaque-access');
      expect(await stored(container, CacheKeys.accessTokenExpiry), isNull);
      expect(await stored(container, CacheKeys.refreshTokenExpiry), isNull);
      expect(router.pushed.single, isA<CreateTransactionPinRoute>());
    });
  });
}
