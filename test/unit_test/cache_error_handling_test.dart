import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/storage/local_cache_service.dart';
import 'package:paypadi/core/services/storage/secure_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Preferences holding a single string value.
class _FakePrefs implements SharedPreferencesWithCache {
  _FakePrefs(this._values);
  final Map<String, String> _values;

  @override
  String? getString(String key) => _values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureCacheService.get', () {
    setUp(
      () => FlutterSecureStorage.setMockInitialValues({'user': 'not-json'}),
    );

    test(
      'returns null instead of throwing when the parser throws an Error',
      () async {
        final cache = SecureCacheService(monitoring: _NoopMonitoring());

        final value = await cache.get<Map<String, dynamic>>(
          'user',
          (raw) => raw as Map<String, dynamic>, // TypeError: raw is a String
        );

        expect(value, isNull);
      },
    );
  });

  group('LocalCacheService.get', () {
    test('returns null instead of throwing when stored JSON has the wrong '
        'shape', () async {
      final cache = LocalCacheService(
        sharedPreferences: _FakePrefs({'profile': '[1, 2, 3]'}),
        monitoring: _NoopMonitoring(),
      );

      expect(await cache.get<Map<String, dynamic>>('profile'), isNull);
    });
  });
}
