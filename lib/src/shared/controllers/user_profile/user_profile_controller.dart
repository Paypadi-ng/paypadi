import 'dart:async';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/models/user_profile_model/user_profile_model.dart';
import 'package:paypadi/core/repositories/profile/i_profile_repository.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_controller.g.dart';

@Riverpod(keepAlive: true)
Map<String, dynamic> profilePayload(Ref ref) => <String, dynamic>{};

@riverpod
class UserProfile extends _$UserProfile {
  late final IProfileRepository _profileRepository;

  @override
  FutureOr<UserProfileModel?> build() async {
    _profileRepository = ref.watch(profileRepositoryProvider);
    final result = await _profileRepository.getUser();

    return result.fold(
      (success) => success.data,
      (failure) {
        ref.showExceptionMessage(failure);
        return null;
      },
    );
  }

  Future<void> changePassword(String newPassword) async {
    state = const AsyncLoading();

    final oldPassword = await ref
        .read(secureCacheProvider)
        .get<String?>(CacheKeys.password);

    final payload = <String, dynamic>{
      'old_password': oldPassword,
      'new_password': newPassword,
    };

    final result = await _profileRepository.changePassword(payload: payload);

    await result.fold(
      (success) async {
        unawaited(
          ref
              .read(secureCacheProvider)
              .save(key: CacheKeys.password, value: newPassword),
        );
        ref.read(appRouterProvider).popUntilRoot();
        state = const AsyncData(null);
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }

  Future<void> changePin(String newPin, String confirmedPin) async {
    state = const AsyncLoading();

    final currentPin = await ref
        .read(secureCacheProvider)
        .get<String?>(CacheKeys.transactionPin);

    final Map<String, dynamic> payload = {
      'new_pin': newPin,
      'current_pin': currentPin,
      'confirm_pin': confirmedPin,
    };

    final result = await _profileRepository.setPin(payload: payload);
    await result.fold(
      (success) async {
        unawaited(
          ref
              .read(secureCacheProvider)
              .save(key: CacheKeys.transactionPin, value: confirmedPin),
        );
        ref.read(appRouterProvider).popUntilRoot();
        state = const AsyncData(null);
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }
}

@riverpod
class RiderProfile extends _$RiderProfile {
  late final IProfileRepository _profileRepository;

  @override
  FutureOr<void> build() {
    _profileRepository = ref.watch(profileRepositoryProvider);
  }

  Future<void> setTransactionPin(String newPin, String confirmedPin) async {
    state = const AsyncLoading();
    final Map<String, dynamic> payload = {
      'new_pin': newPin,
      'confirm_pin': confirmedPin,
    };

    final result = await _profileRepository.setPin(payload: payload);
    await result.fold(
      (success) async {
        unawaited(
          ref
              .read(secureCacheProvider)
              .save(key: CacheKeys.transactionPin, value: confirmedPin),
        );
        await ref
            .read(appRouterProvider)
            .push(const BiometricAuthenticationRoute());
        state = const AsyncData(null);
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }
}

@riverpod
class DriverProfile extends _$DriverProfile {
  late final IProfileRepository _profileRepository;

  @override
  FutureOr<void> build() {
    _profileRepository = ref.watch(profileRepositoryProvider);
  }

  Future<void> createProfile() async {
    state = const AsyncLoading();

    final payload = ref.read(profilePayloadProvider);
    final result = await _profileRepository.createDriverProfile(payload);

    result.fold(
      (success) {
        state = const AsyncData(null);
        unawaited(ref.read(appRouterProvider).push(const LicensingRoute()));
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }

  Future<void> updateDriverProfile() async {
    state = const AsyncLoading();

    final payload = ref.read(profilePayloadProvider);
    final result = await _profileRepository.updateDriverProfile(payload);

    result.fold(
      (success) {
        state = const AsyncData(null);
        unawaited(
          ref.read(appRouterProvider).push(const DocumentUploadRoute()),
        );
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }
}
