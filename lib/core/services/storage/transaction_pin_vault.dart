import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:talker_flutter/talker_flutter.dart' show Talker;

/// Holds the transaction PIN for biometric payment confirmation.
///
/// The PIN lives in its own store, separate from [SecureCacheService], and
/// the operating system only releases it after a biometric check:
/// - Android: a hardware-backed key that needs strong biometrics on every
///   read or write.
/// - iOS: a Keychain item bound to the currently enrolled Face ID/Touch ID
///   and only available while the device has a passcode.
///
/// When the device's biometrics change, the OS invalidates the key and this
/// store is wiped. That only means the user types their PIN again: the
/// session tokens in [SecureCacheService] are unaffected.
///
/// Every method fails closed: a cancelled prompt, missing biometrics or a
/// storage error reads as "no PIN" and never throws.
class TransactionPinVault {
  TransactionPinVault({
    required MonitoringService monitoring,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _monitoring = monitoring;

  /// Android: a dedicated namespace so a reset only ever affects this store.
  static const AndroidOptions androidOptions = AndroidOptions.biometric(
    enforceBiometrics: true,
    requireBiometricsPerOperation: true,
    biometricType: AndroidBiometricType.strongBiometricOnly,
    storageNamespace: 'paypadi_transaction_pin',
    biometricPromptTitle: 'Confirm payment',
    biometricPromptSubtitle: 'Use your fingerprint or face to continue',
    biometricPromptNegativeButton: 'Enter PIN instead',
  );

  /// iOS: removed if Face ID/Touch ID enrolment changes or the passcode is
  /// turned off, and never backed up or synced.
  static const IOSOptions iosOptions = IOSOptions(
    accountName: 'paypadi_transaction_pin',
    accessibility: KeychainAccessibility.passcode,
    accessControlFlags: [AccessControlFlag.biometryCurrentSet],
  );

  static const String _key = 'transaction_pin';

  final FlutterSecureStorage _storage;
  final MonitoringService _monitoring;
  final Talker _logger = debugLogger;

  /// Stores [pin], prompting for biometrics on Android. Returns whether it
  /// was saved; on devices without strong biometrics it isn't.
  Future<bool> save(String pin) async {
    try {
      await _storage.write(
        key: _key,
        value: pin,
        aOptions: androidOptions,
        iOptions: iosOptions,
      );
      return true;
    } catch (e, st) {
      await _report(e, st, 'write');
      return false;
    }
  }

  /// Shows the system biometric prompt and returns the PIN, or `null` if
  /// none is stored, the user cancels, or the key was invalidated.
  Future<String?> read() async {
    try {
      return await _storage.read(
        key: _key,
        aOptions: androidOptions,
        iOptions: iosOptions,
      );
    } catch (e, st) {
      await _report(e, st, 'read');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(
        key: _key,
        aOptions: androidOptions,
        iOptions: iosOptions,
      );
    } catch (e, st) {
      await _report(e, st, 'delete');
    }
  }

  Future<void> _report(Object e, StackTrace st, String operation) async {
    // Cancelled prompts land here too, so this is a warning, not an error.
    // The PIN itself is never logged.
    _logger.warning('$runtimeType: $operation failed', e, st);
    await _monitoring.captureException(
      e,
      stackTrace: st,
      context: 'TransactionPinVault',
      level: SeverityLevel.warning,
      extras: {'operation': operation},
    );
  }
}
