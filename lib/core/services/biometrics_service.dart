import 'package:local_auth/local_auth.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';

class BiometricsService {
  final LocalAuthentication _service = LocalAuthentication();

  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _service.canCheckBiometrics;
      final bool isDeviceSupported = await _service.isDeviceSupported();

      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (e, st) {
      // Pass to handler to ensure it gets logged to Sentry via logger
      AppException.handleException(e, st);
      return false;
    }
  }

  Future<List<BiometricType>> deviceBiometricTypes() async {
    try {
      return await _service.getAvailableBiometrics();
    } catch (e, st) {
      AppException.handleException(e, st);
      return []; // Return empty list on failure so the UI doesn't crash
    }
  }

  Future<bool> authenticate([String? reason]) async {
    try {
      final didAuthenticate = await _service.authenticate(
        localizedReason: reason ?? 'Sign in to Paypadi',
        biometricOnly: true, // no PIN/password fallback inside prompt
        persistAcrossBackgrounding: true, // persists across app backgrounding
      );
      return didAuthenticate;
    } catch (e, st) {
      throw AppException.handleException(e, st);
    }
  }
}
