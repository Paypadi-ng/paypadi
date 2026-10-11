import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/notifications/notifications_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/authentication/i_authentication_repository.dart';
import 'package:paypadi/data/authentication/models/auth_responses.dart';
import 'package:paypadi/data/authentication/models/user_model.dart';
import 'package:paypadi/data/authentication/providers.dart';
import 'package:paypadi/data/profile/i_profile_repository.dart';
import 'package:paypadi/data/profile/models/user_profile_model.dart';
import 'package:paypadi/data/profile/providers.dart';
import 'package:paypadi/features/authentication/controllers/authentication_controller.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';
import 'package:paypadi/shared/controllers/user_profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/transfer_fakes.dart';

/// A driver straight out of sign-up: not approved, no vehicle details yet.
final _newDriver = UserModel(
  id: 'd1',
  role: 'driver',
  phoneNumber: '08031234567',
  firstName: 'Ada',
  lastName: 'Obi',
  isActive: true,
  phoneVerified: true,
  dateJoined: DateTime.utc(2026, 10, 2),
  isDriver: true,
  isApproved: false,
);

class _DriverAuthRepository implements IAuthenticationRepository {
  @override
  FutureResultOf<ApiResponse<LoginResponse>> login(
    Map<String, dynamic> payload,
  ) async => success(
    ok(
      LoginResponse(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessTokenExpiry: 0,
        refreshTokenExpiry: 0,
        user: _newDriver,
      ),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _SavingProfileRepository implements IProfileRepository {
  @override
  FutureApiResultOf<DriverProfileModel> createDriverProfile(
    Map<String, dynamic> payload,
  ) async => success(
    ok(
      const DriverProfileModel(
        id: 1,
        totalRides: 0,
        isApproved: false,
        isAvailable: false,
        submittedForApproval: true,
        createdAt: '2026-10-02',
        updatedAt: '2026-10-02',
        licensePlate: 'LND-123-AB',
      ),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Shared preferences kept in a map.
class _MemoryPrefs implements SharedPreferencesWithCache {
  final values = <String, Object>{};

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _QuietNotifications implements INotificationsService {
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

  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        authenticationRepositoryProvider.overrideWithValue(
          _DriverAuthRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(_SavingProfileRepository()),
        sharedPreferencesFutureProvider.overrideWith(
          (ref) async => _MemoryPrefs(),
        ),
        notificationsServiceProvider.overrideWithValue(_QuietNotifications()),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(authenticationControllerProvider, (_, _) {})
      ..listen(driverProfileProvider, (_, _) {});
  });

  Future<bool?> owesVehicleInfo() async {
    final cache = await container.read(localCacheProvider.future);
    return cache.get<bool>(CacheKeys.driverNeedsVehicleInfo);
  }

  test('signing in as a driver with no vehicle details yet marks them for the '
      'driver guard', () async {
    await container
        .read(authenticationControllerProvider.notifier)
        .login('08031234567', '654321');

    expect(await owesVehicleInfo(), isTrue);
  });

  test('saving the vehicle details lets the driver through', () async {
    await container
        .read(authenticationControllerProvider.notifier)
        .login('08031234567', '654321');

    await container.read(driverProfileProvider.notifier).createProfile();

    expect(await owesVehicleInfo(), isFalse);
  });
}
