import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/settings/controller/settings_controller.dart';
import 'package:paypadi/src/features/transfer/controller/transaction_controller.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class AuthenticateTransferScreen extends HookConsumerWidget {
  const AuthenticateTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinController = useTextEditingController();
    final settings = ref.watch(settingsControllerProvider);
    final biometricService = ref.watch(biometricsProvider);

    ref.listen(initiatePaymentControllerProvider, (previous, current) {
      current.when(
        data: (d) {
          pinController.clear();
          ref.dismissLoading();
        },
        error: (e, st) {
          pinController.clear();
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
          AppPinIndicator(controller: pinController),
          const Spacer(flex: 2),
          AppKeypad(
            controller: pinController,
            showBiometric: settings.value?.biometricsIsEnabled ?? false,

            padding: const EdgeInsets.symmetric(horizontal: Values.v24),
            onBiometricKeyPressed: () async {
              final isAuthenticated = await biometricService.authenticate();

              if (isAuthenticated) {
                final pin = await ref
                    .read(secureCacheProvider)
                    .get<String>(CacheKeys.transactionPin);

                if (pin == null) return;

                pinController.text = pin;
                ref.read(transactionPayloadProvider)['pin'] = pin;
                await ref
                    .read(initiatePaymentControllerProvider.notifier)
                    .initiatePayment();
              }
            },

            onSubmit: (value) async {
              ref.read(transactionPayloadProvider)['pin'] = value;
              await ref
                  .read(initiatePaymentControllerProvider.notifier)
                  .initiatePayment();
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
