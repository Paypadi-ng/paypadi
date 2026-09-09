import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/shared/controllers/user_profile/user_profile_controller.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class ConfirmPasswordScreen extends HookConsumerWidget {
  const ConfirmPasswordScreen({
    required this.password,
    this.isUpdating = false,
    super.key,
  });

  final String password;
  final bool isUpdating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmPasswordController = useTextEditingController();

    ref.listen(authenticationControllerProvider, (previous, current) {
      current.when(
        data: (d) {
          confirmPasswordController.clear();
          ref.dismissLoading();
        },
        error: (e, st) {
          confirmPasswordController.clear();
          ref.dismissLoading();
          ref.showExceptionMessage(e, st);
        },
        loading: () => ref.showLoading(),
      );
    });

    ref.listen(userProfileProvider, (previous, current) {
      current.when(
        data: (d) {
          confirmPasswordController.clear();
          ref.dismissLoading();
        },
        error: (e, st) {
          confirmPasswordController.clear();
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
            'Confirm your Password',
            style: context.textTheme.headlineMedium,
          ),
          Values.v12.verticalSpace,
          Text(
            'Set a secure password for your account',
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Values.v32.verticalSpace,
          AppPinIndicator(
            pinLength: passwordPinLength,
            controller: confirmPasswordController,
          ),
          const Spacer(flex: 3),
          AppKeypad(
            keyLength: passwordPinLength,
            controller: confirmPasswordController,
            onSubmit: (confirmedPassword) async {
              if (isUpdating) {
                await changePassword(ref, password);
                return;
              }
              await createAccount(ref, password, confirmedPassword);
              confirmPasswordController.clear();
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> createAccount(
    WidgetRef ref,
    String password,
    String confirmedPassword,
  ) async {
    if (password == confirmedPassword) {
      ref.read(authenticationPayloadProvider)['password'] = password;
      await ref.read(authenticationControllerProvider.notifier).register();
    }
  }

  Future<void> changePassword(WidgetRef ref, String password) async {
    await ref.read(userProfileProvider.notifier).changePassword(password);
  }
}
