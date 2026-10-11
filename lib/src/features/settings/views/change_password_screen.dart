import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();

    return AppScaffold(
      title: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Password',
            style: context.textTheme.headlineMedium,
          ),
          Values.v12.verticalSpace,
          Text(
            'Please enter your Password',
            style: context.textTheme.bodyMedium?.copyWith(
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
            // The password isn't kept on the device, so it can't be checked
            // here: it's sent with the new one and the server verifies it.
            onSubmit: (currentPassword) async {
              passwordController.clear();
              await ref
                  .read(appRouterProvider)
                  .push(
                    CreatePasswordRoute(
                      isUpdating: true,
                      currentPassword: currentPassword,
                    ),
                  );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
