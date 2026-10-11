import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/features/account_security/controllers/account_security_controller.dart';
import 'package:paypadi/shared/controllers/user_profile_controller.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_keypad.dart';
import 'package:paypadi/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

/// Shown when the confirmation doesn't match the PIN entered first.
const pinMismatchMessage = "The PINs don't match. Enter the same PIN again.";

@RoutePage()
class ConfirmTransactionPinScreen extends HookConsumerWidget {
  const ConfirmTransactionPinScreen({
    required this.pin,
    this.isUpdating = false,
    this.currentPin,
    super.key,
  });

  final String pin;
  final bool isUpdating;

  /// The PIN being replaced, when [isUpdating]; the server checks it.
  final String? currentPin;

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

    // Only when changing an existing PIN/password; sign-up has its own
    // listener above.
    if (isUpdating) {
      ref.listen(accountSecurityProvider, (previous, current) {
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
    }

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
            onSubmit: (confirmedPin) async {
              // Checked for both new and changed PINs: without this the
              // keypad stayed full and nothing said why.
              if (confirmedPin != pin) {
                confirmPinController.clear();
                ref.showErrorToast(pinMismatchMessage);
                return;
              }
              if (isUpdating) {
                await changePin(ref);
              } else {
                await setPin(ref);
              }
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> setPin(WidgetRef ref) =>
      ref.read(riderProfileProvider.notifier).setTransactionPin(pin, pin);

  Future<void> changePin(WidgetRef ref) async {
    final current = currentPin;
    if (current == null) return;
    await ref
        .read(accountSecurityProvider.notifier)
        .changePin(currentPin: current, newPin: pin, confirmedPin: pin);
  }
}
