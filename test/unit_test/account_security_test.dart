import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/profile/i_profile_repository.dart';
import 'package:paypadi/data/profile/models/user_profile_model.dart';
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';

import '../helpers/transfer_fakes.dart';

const _profile = UserProfileModel(
  id: 'u1',
  role: AccountType.rider,
  phoneNumber: '+2348031234567',
  firstName: 'Ada',
  lastName: 'Obi',
  isActive: true,
  phoneVerified: true,
  dateJoined: '2026-10-01T09:00:00Z',
  totalReferrals: 0,
);

/// Serves the profile and accepts every password and PIN change.
class _ProfileRepository implements IProfileRepository {
  @override
  FutureResultOf<ApiResponse<UserProfileModel>> getUser() async =>
      success(ok(_profile));

  @override
  FutureApiResultOf<void> changePassword({
    required Map<String, dynamic> payload,
  }) async => success(ok<void>(null));

  @override
  FutureApiResultOf<void> changePin({
    required Map<String, dynamic> payload,
  }) async => success(ok<void>(null));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late RecordingRouter router;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        profileRepositoryProvider.overrideWithValue(_ProfileRepository()),
        transactionPinVaultProvider.overrideWithValue(FakePinVault()),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    router = container.read(appRouterProvider) as RecordingRouter;
    // Home keeps the profile loaded; the change screen listens to the change.
    container
      ..listen(userProfileProvider, (_, _) {})
      ..listen(accountSecurityProvider, (_, _) {});
    await container.read(userProfileProvider.future);
  });

  AccountSecurity security() =>
      container.read(accountSecurityProvider.notifier);

  test('changing the password leaves the loaded profile in place', () async {
    await security().changePassword(
      currentPassword: '135790',
      newPassword: '246801',
    );

    expect(container.read(userProfileProvider).value, _profile);
    expect(container.read(accountSecurityProvider).isLoading, isFalse);
    expect(router.poppedToRoot, 1);
  });

  test('changing the PIN leaves the loaded profile in place', () async {
    await security().changePin(
      currentPin: '1111',
      newPin: '2222',
      confirmedPin: '2222',
    );

    expect(container.read(userProfileProvider).value, _profile);
    expect(router.poppedToRoot, 1);
  });
}
