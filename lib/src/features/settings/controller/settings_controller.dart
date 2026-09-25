import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_state.dart';
part 'settings_controller.freezed.dart';
part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  @override
  FutureOr<SettingsState> build() async {
    final localCache = await ref.watch(localCacheProvider.future);
    final biometricsEnabled = await localCache.get<bool>(CacheKeys.biometrics);
    final darkModeIsEnabled = await localCache.get<bool>(CacheKeys.darkMode);

    return SettingsState(
      biometricsIsEnabled: biometricsEnabled ?? false,
      darkModeIsEnabled: darkModeIsEnabled ?? false,
    );
  }

  Future<void> enableBiometrics({required bool biometrics}) async {
    final localCache = await ref.read(localCacheProvider.future);
    await localCache.save(key: CacheKeys.biometrics, value: biometrics);

    state = AsyncData(state.value!.copyWith(biometricsIsEnabled: biometrics));
  }

  Future<void> enableDarkMode({required bool darkMode}) async {
    final localCache = await ref.read(localCacheProvider.future);
    await localCache.save(key: CacheKeys.darkMode, value: darkMode);

    state = AsyncData(state.value!.copyWith(darkModeIsEnabled: darkMode));
  }
}
