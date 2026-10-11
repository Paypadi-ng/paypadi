import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/shared/widgets/app_keypad.dart';
import 'package:paypadi/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

@RoutePage()
class CreatePasswordScreen extends HookConsumerWidget {
  const CreatePasswordScreen({
    this.isUpdating = false,
    this.currentPassword,
    super.key,
  });
  final bool isUpdating;

  /// The password being replaced, when [isUpdating]; the server checks it.
  final String? currentPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Values.v32.verticalSpace,
          Text(
            'Create your Password',
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
            controller: passwordController,
          ),
          const Spacer(flex: 3),
          AppKeypad(
            keyLength: passwordPinLength,
            controller: passwordController,
            onSubmit: (value) {
              onSubmit(ref, value);
              passwordController.clear();
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void onSubmit(WidgetRef ref, String password) {
    unawaited(
      ref
          .read(appRouterProvider)
          .push(
            ConfirmPasswordRoute(
              password: password,
              isUpdating: isUpdating,
              currentPassword: currentPassword,
            ),
          ),
    );
  }
}
