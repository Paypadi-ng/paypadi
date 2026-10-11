import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/storage/transaction_pin_vault.dart';

/// Records reports so tests can check failures are surfaced, never thrown.
class _RecordingMonitoring implements MonitoringService {
  final List<Object> exceptions = [];

  @override
  Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
    SeverityLevel level = SeverityLevel.error,
  }) async => exceptions.add(exception);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// In-memory storage that records the options each call used and can be
/// told to fail, as a cancelled biometric prompt does.
class _FakeStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};
  final List<AndroidOptions?> androidOptions = [];
  final List<AppleOptions?> iosOptions = [];
  Object? failWith;

  void _record(AndroidOptions? a, AppleOptions? i) {
    androidOptions.add(a);
    iosOptions.add(i);
    if (failWith case final error?) throw error;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _record(aOptions, iOptions);
    values[key] = value!;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _record(aOptions, iOptions);
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _record(aOptions, iOptions);
    values.remove(key);
  }
}

void main() {
  late _FakeStorage storage;
  late _RecordingMonitoring monitoring;
  late TransactionPinVault vault;

  setUp(() {
    storage = _FakeStorage();
    monitoring = _RecordingMonitoring();
    vault = TransactionPinVault(monitoring: monitoring, storage: storage);
  });

  group('TransactionPinVault', () {
    test('stores and returns the PIN', () async {
      expect(await vault.save('1234'), isTrue);
      expect(await vault.read(), '1234');
    });

    test('has no PIN until one is saved, and none after clearing', () async {
      expect(await vault.read(), isNull);

      await vault.save('1234');
      await vault.clear();

      expect(await vault.read(), isNull);
    });

    test('always uses the biometric-gated options', () async {
      await vault.save('1234');
      await vault.read();
      await vault.clear();

      expect(
        storage.androidOptions,
        everyElement(same(TransactionPinVault.androidOptions)),
      );
      expect(
        storage.iosOptions,
        everyElement(same(TransactionPinVault.iosOptions)),
      );
    });

    test('requires strong biometrics on Android in its own namespace', () {
      final options = TransactionPinVault.androidOptions.toMap();

      expect(options['enforceBiometrics'], 'true');
      expect(options['requireBiometricsPerOperation'], 'true');
      expect(options['biometricType'], contains('strongBiometricOnly'));
      expect(options['storageNamespace'], 'paypadi_transaction_pin');
    });

    test('is bound to the enrolled biometrics and a passcode on iOS', () {
      const options = TransactionPinVault.iosOptions;

      expect(options.accessControlFlags, [
        AccessControlFlag.biometryCurrentSet,
      ]);
      expect(options.accessibility, KeychainAccessibility.passcode);
      expect(options.accountName, 'paypadi_transaction_pin');
    });

    test(
      'reads as no PIN when the prompt is cancelled, and reports it',
      () async {
        await vault.save('1234');
        storage.failWith = Exception('user cancelled');

        expect(await vault.read(), isNull);
        expect(monitoring.exceptions, hasLength(1));
      },
    );

    test('reports a failed save without throwing', () async {
      storage.failWith = Exception('no biometrics enrolled');

      expect(await vault.save('1234'), isFalse);
      expect(monitoring.exceptions, hasLength(1));
    });

    test('a failed clear does not throw', () async {
      storage.failWith = Exception('keystore unavailable');

      await expectLater(vault.clear(), completes);
    });
  });
}
