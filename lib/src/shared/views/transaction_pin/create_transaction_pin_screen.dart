import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class CreateTransactionPinScreen extends HookConsumerWidget {
  const CreateTransactionPinScreen({this.isUpdating = false, super.key});
  final bool isUpdating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinController = useTextEditingController();

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Values.v32.verticalSpace,
          Text(
            'Create a Transaction PIN',
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
            controller: pinController,
          ),
          const Spacer(flex: 3),
          AppKeypad(
            controller: pinController,
            onSubmit: (pin) => onSubmit(ref, pin),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void onSubmit(WidgetRef ref, String pin) {
    unawaited(
      ref
          .read(appRouterProvider)
          .push(ConfirmTransactionPinRoute(pin: pin, isUpdating: isUpdating)),
    );
  }
}
