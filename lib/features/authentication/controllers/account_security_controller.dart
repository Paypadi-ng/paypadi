import 'dart:async';

import 'package:paypadi/app/providers.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/data/profile/providers.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_security_controller.g.dart';

/// Changes the signed-in user's password and transaction PIN.
///
/// Its loading state drives the change screens. These used to run on
/// [UserProfile], so finishing a change left that provider holding null:
/// Home lost the user's name, and the wallet card showed "Refresh this page",
/// until the profile was loaded again.
@riverpod
class AccountSecurity extends _$AccountSecurity {
  @override
  FutureOr<void> build() {}

  /// Changes the password. [currentPassword] is what the user just typed;
  /// passwords are never kept on the device, so the server checks it.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();

    final payload = <String, dynamic>{
      'old_password': currentPassword,
      'new_password': newPassword,
    };

    final result = await ref
        .read(profileRepositoryProvider)
        .changePassword(payload: payload);
    if (!ref.mounted) return;

    result.fold(
      (success) {
        // Delete any copy an older version kept on the device.
        unawaited(
          ref.read(secureCacheProvider).remove(CacheKeys.legacyPassword),
        );
        state = const AsyncData(null);
        ref.read(appRouterProvider).popUntilRoot();
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
    if (state.isLoading) return;
    state = const AsyncLoading();

    final Map<String, dynamic> payload = {
      'current_pin': currentPin,
      'new_pin': newPin,
      'confirm_pin': confirmedPin,
    };

    final result = await ref
        .read(profileRepositoryProvider)
        .changePin(payload: payload);
    if (!ref.mounted) return;

    result.fold(
      (success) {
        // The biometric copy holds the old PIN; it's re-saved the next time
        // the new PIN is typed for a payment. Also delete any plain copy an
        // older version kept on the device.
        unawaited(ref.read(transactionPinVaultProvider).clear());
        unawaited(
          ref.read(secureCacheProvider).remove(CacheKeys.legacyTransactionPin),
        );
        state = const AsyncData(null);
        ref.read(appRouterProvider).popUntilRoot();
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }
}
