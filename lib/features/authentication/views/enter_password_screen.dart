import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/features/authentication/controllers/authentication_controller.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_keypad.dart';
import 'package:paypadi/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

@RoutePage()
class EnterPasswordScreen extends HookConsumerWidget {
  const EnterPasswordScreen({required this.phoneNumber, super.key});
  final String phoneNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();

    ref.listen(
      authenticationControllerProvider,
      (previous, current) {
        current.when(
          data: (d) {
            ref.dismissLoading();
            passwordController.clear();
          },
          error: (e, st) {
            ref.dismissLoading();
            passwordController.clear();
          },
          loading: () => ref.showLoading(),
        );
      },
    );

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Values.v32.verticalSpace,
          Text(
            'Enter Password',
            style: context.textTheme.headlineMedium,
          ),
          Values.v12.verticalSpace,
          Text(
            'Enter the password associated with your account',
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Values.v64.verticalSpace,
          AppPinIndicator(
            pinLength: passwordPinLength,
            controller: passwordController,
          ),
          const Spacer(flex: 3),
          AppKeypad(
            keyLength: passwordPinLength,
            controller: passwordController,
            onSubmit: (value) => onSubmit(ref, value),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void onSubmit(WidgetRef ref, String password) {
    unawaited(
      ref
          .read(authenticationControllerProvider.notifier)
          .login(phoneNumber, password),
    );
  }
}
