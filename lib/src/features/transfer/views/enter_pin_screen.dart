import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/transfer/controller/transaction_controller.dart';
import 'package:paypadi/src/features/transfer/controller/transfer_draft.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class EnterPinScreen extends HookConsumerWidget {
  const EnterPinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinController = useTextEditingController();
    final biometricService = ref.watch(biometricsProvider);

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
          ref.dismissLoading();
          ref.showExceptionMessage(e, st);
        },
        loading: () => ref.showLoading(),
      );
    });

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
            'Enter transaction 4-digit PIN-code or use your biometrics to perform action.',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Values.v64.verticalSpace,
          AppPinIndicator(
            controller: pinController,
          ),
          const Spacer(flex: 2),
          AppKeypad(
            showBiometric: true,
            controller: pinController,
            padding: const EdgeInsets.symmetric(horizontal: Values.v24),
            onBiometricKeyPressed: () async {
              await biometricService.authenticate();

              // final String? pin = await ref
              //     .read(secureCacheProvider)
              //     .read(CacheKeys.transactionPin);

              // if (pin == null) return;

              // ref.read(transactionPayloadProvider)['pin'] = pin;
              // ref
              //     .read(initiatePaymentControllerProvider.notifier)
              //     .initiatePayment();
            },

            onSubmit: (value) {
              ref.read(transferDraftControllerProvider.notifier).setPin(value);

              unawaited(
                ref
                    .read(initiatePaymentControllerProvider.notifier)
                    .initiatePayment(),
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
