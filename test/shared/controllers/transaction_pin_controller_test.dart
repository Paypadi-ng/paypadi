import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/data/profile/i_profile_repository.dart';
import 'package:paypadi/data/profile/providers.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';
import 'package:paypadi/shared/controllers/user_profile_controller.dart';

import '../../helpers/transfer_fakes.dart';

class _FakeProfileRepository implements IProfileRepository {
  @override
  Future<Result<ApiResponse<void>, Exception>> setPin({
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

  test('stops loading once the PIN is set, while the biometrics screen is '
      'still open', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
        appRouterProvider.overrideWith((ref) => PendingPushRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider) as PendingPushRouter;
    container.listen(riderProfileProvider, (_, _) {});

    await container
        .read(riderProfileProvider.notifier)
        .setTransactionPin('1234', '1234');

    // The biometrics screen was pushed and is still on screen (not popped),
    // yet the loading state, and with it the overlay, has cleared.
    expect(router.pushed.single, isA<BiometricAuthenticationRoute>());
    expect(container.read(riderProfileProvider).isLoading, isFalse);
  });
}
