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
  late IProfileRepository _profileRepository;

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

  /// Changes the password. [currentPassword] is what the user just typed;
  /// passwords are never kept on the device, so the server checks it.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();

    final payload = <String, dynamic>{
      'old_password': currentPassword,
      'new_password': newPassword,
    };

    final result = await _profileRepository.changePassword(payload: payload);

    await result.fold(
      (success) async {
        // Delete any copy an older version kept on the device.
        unawaited(
          ref.read(secureCacheProvider).remove(CacheKeys.legacyPassword),
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

  /// Changes the transaction PIN. [currentPin] is what the user just typed;
  /// the server checks it.
  Future<void> changePin({
    required String currentPin,
    required String newPin,
    required String confirmedPin,
  }) async {
    state = const AsyncLoading();

    final Map<String, dynamic> payload = {
      'current_pin': currentPin,
      'new_pin': newPin,
      'confirm_pin': confirmedPin,
    };

    final result = await _profileRepository.changePin(payload: payload);
    await result.fold(
      (success) async {
        // The biometric copy holds the old PIN; it's re-saved the next time
        // the new PIN is typed for a payment. Also delete any plain copy an
        // older version kept on the device.
        unawaited(ref.read(transactionPinVaultProvider).clear());
        unawaited(
          ref.read(secureCacheProvider).remove(CacheKeys.legacyTransactionPin),
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
  late IProfileRepository _profileRepository;

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
        // The PIN is only ever checked by the server; delete any copy an
        // older version kept on the device.
        unawaited(
          ref.read(secureCacheProvider).remove(CacheKeys.legacyTransactionPin),
        );
        // Settle before navigating: push() only completes once the next
        // screen is popped, so awaiting it first left this in loading, and
        // the loading overlay blocked the biometrics screen.
        state = const AsyncData(null);
        unawaited(
          ref
              .read(appRouterProvider)
              .push(const BiometricAuthenticationRoute()),
        );
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
  late IProfileRepository _profileRepository;

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
