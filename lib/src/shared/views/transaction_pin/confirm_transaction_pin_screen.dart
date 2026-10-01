import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

/// Shown when the confirmation doesn't match the PIN entered first.
const pinMismatchMessage = "The PINs don't match. Enter the same PIN again.";

@RoutePage()
class ConfirmTransactionPinScreen extends HookConsumerWidget {
  const ConfirmTransactionPinScreen({required this.pin, super.key});
  final String pin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmPinController = useTextEditingController();

    ref.listen(riderProfileProvider, (previous, current) {
      current.when(
        data: (d) {
          confirmPinController.clear();
          ref.dismissLoading();
        },
        error: (e, st) {
          confirmPinController.clear();
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
          Values.v32.verticalSpace,
          Text(
            'Confirm Transaction Pin',
            style: context.textTheme.headlineMedium,
          ),
          Values.v12.verticalSpace,
          Text(
            'Enter the same 4-digit PIN again to confirm it.',
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Values.v32.verticalSpace,
          AppPinIndicator(
            controller: confirmPinController,
          ),
          const Spacer(flex: 3),
          AppKeypad(
            controller: confirmPinController,
            onSubmit: (confirmedPin) =>
                submitPin(ref, confirmPinController, confirmedPin),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> submitPin(
    WidgetRef ref,
    TextEditingController field,
    String confirmedPin,
  ) async {
    if (confirmedPin != pin) {
      // Without this the keypad stayed full and nothing said why.
      field.clear();
      ref.showErrorToast(pinMismatchMessage);
      return;
    }

    await ref
        .read(riderProfileProvider.notifier)
        .setTransactionPin(pin, confirmedPin);
  }
}
