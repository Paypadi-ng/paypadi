import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/features/settings/controllers/settings_controller.dart';
import 'package:paypadi/features/transfer/controllers/transaction_controller.dart';
import 'package:paypadi/features/transfer/controllers/transfer_draft.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_keypad.dart';
import 'package:paypadi/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

@RoutePage()
class AuthenticateTransferScreen extends HookConsumerWidget {
  const AuthenticateTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinController = useTextEditingController();
    final biometricsEnabled =
        ref.watch(settingsControllerProvider).value?.biometricsIsEnabled ??
        false;

    ref.listen(initiatePaymentControllerProvider, (previous, current) {
      current.when(
        data: (payment) {
          ref.dismissLoading();
          // A failed attempt leaves the keypad full; clear it so the user
          // can enter the PIN again.
          if (previous?.isLoading == true && payment == null) {
            pinController.clear();
          }
        },
        error: (e, st) {
          pinController.clear();
          ref.dismissLoading();
          ref.showExceptionMessage(e, st);
        },
        loading: () => ref.showLoading(),
      );
    });

    void pay(String pin, {required bool fromVault}) {
      ref.read(transferDraftControllerProvider.notifier).setPin(pin);
      unawaited(
        ref
            .read(initiatePaymentControllerProvider.notifier)
            .initiatePayment(
              pinFromVault: fromVault,
              rememberPin: biometricsEnabled,
            ),
      );
    }

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Values.v24.verticalSpace,
          Text(
            'Enter PIN',
            style: context.textTheme.headlineMedium,
          ),
          Values.v12.verticalSpace,
          Text(
            'Enter your 4-digit transaction PIN to confirm this payment.',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Values.v64.verticalSpace,
          AppPinIndicator(controller: pinController),
          const Spacer(flex: 2),
          AppKeypad(
            controller: pinController,
            showBiometric: biometricsEnabled,
            padding: const EdgeInsets.symmetric(horizontal: Values.v24),
            // Reading the vault shows the system biometric prompt; the PIN
            // is only released after the OS verifies the user.
            onBiometricKeyPressed: () async {
              final pin = await ref.read(transactionPinVaultProvider).read();
              if (!context.mounted) return;

              if (pin == null) {
                ref.showExceptionMessage(
                  const ClientException(
                    message:
                        'Enter your PIN once to use biometrics for payments.',
                  ),
                );
                return;
              }

              pinController.text = pin;
              pay(pin, fromVault: true);
            },
            onSubmit: (value) => pay(value, fromVault: false),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
