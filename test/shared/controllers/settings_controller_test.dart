import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/shared/controllers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared preferences kept in a map that outlives each container, like the
/// device's storage between launches.
class _MemoryPrefs implements SharedPreferencesWithCache {
  _MemoryPrefs(this.values);
  final Map<String, Object> values;

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  final storage = <String, Object>{};

  ProviderContainer launch() {
    final container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        sharedPreferencesFutureProvider.overrideWith(
          (ref) async => _MemoryPrefs(storage),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(settingsControllerProvider, (_, _) {});
    return container;
  }

  setUp(storage.clear);

  test('the app starts in light mode', () async {
    final settings = await launch().read(settingsControllerProvider.future);

    expect(settings.darkModeIsEnabled, isFalse);
  });

  test('turning dark mode on applies straight away and is still on at the '
      'next launch', () async {
    final first = launch();
    await first.read(settingsControllerProvider.future);

    await first
        .read(settingsControllerProvider.notifier)
        .enableDarkMode(darkMode: true);

    expect(
      first.read(settingsControllerProvider).value?.darkModeIsEnabled,
      isTrue,
    );
    final next = await launch().read(settingsControllerProvider.future);
    expect(next.darkModeIsEnabled, isTrue);
  });
}
