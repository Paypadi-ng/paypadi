import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  // late SharedPreferencesWithCache prefs;
  // late LocalCacheService cache;
  // initialize a logger for debugging tests if needed
  final _ = TalkerFlutter.init();

  setUpAll(() async {
    // initialize test binding for Flutter plugins
    TestWidgetsFlutterBinding.ensureInitialized();
    // prepare in-memory shared preferences for tests
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // prefs = await SharedPreferencesWithCache.create(
    //   cacheOptions: const SharedPreferencesWithCacheOptions(
    //     allowList: {
    //       CacheKeys.inAppColor,
    //       CacheKeys.biometrics,
    //       CacheKeys.darkMode,
    //     },
    //   ),
    // );
    // cache = LocalCacheService(sharedPreferences: prefs);
  });
}
//   test('save and retrieve string', () async {
//     await cache.saveToCache(key: 'k1', value: 'hello');
//     final v = cache.getFromCache<String>('k1');
//     expect(v, 'hello');
//   });

//   test('save and retrieve int', () async {
//     await cache.saveToCache(key: 'k2', value: 42);
//     final v = cache.getFromCache<int>('k2');
//     expect(v, 42);
//   });

//   test('save and retrieve map', () async {
//     final m = {'a': 1, 'b': 'two'};
//     await cache.saveToCache(key: 'k3', value: m);
//     final v = cache.getFromCache<Map<String, dynamic>>('k3');
//     expect(v, isNotNull);
//     expect(v!['a'], 1);
//     expect(v['b'], 'two');
//   });

//   test('save and retrieve list', () async {
//     final list = ['a', 'b', 'c'];
//     await cache.saveToCache(key: 'k4', value: list);
//     final v = cache.getFromCache<List<String>>('k4');
//     expect(v, list);
//   });

//   test('setColorTheme stores index', () async {
//     await cache.setColorTheme(2);
//     final idx = cache.getFromCache<int>(CacheKeys.colorTheme);
//     expect(idx, 2);
//   });

//   test('enable/disable biometrics stores correct booleans', () async {
//     await cache.enableBiometrics();
//     var enabled = cache.getFromCache<bool>(CacheKeys.enabledBiometrics);
//     expect(enabled, isTrue);

//     await cache.disableBiometrics();
//     enabled = cache.getFromCache<bool>(CacheKeys.enabledBiometrics);
//     expect(enabled, isFalse);
//   });

//   test('enable/disable dark mode stores correct booleans', () async {
//     await cache.enableDarkMode();
//     var dark = cache.getFromCache<bool>(CacheKeys.isDarkMode);
//     expect(dark, isTrue);

//     await cache.disableDarkMode();
//     dark = cache.getFromCache<bool>(CacheKeys.isDarkMode);
//     expect(dark, isFalse);
//   });

//   test('removeFromCache deletes key', () async {
//     await cache.saveToCache(key: 'tempKey', value: 'temp');
//     expect(cache.getFromCache<String>('tempKey'), 'temp');
//     await cache.removeFromCache('tempKey');
//     expect(cache.getFromCache<String>('tempKey'), isNull);
//   });
// }
