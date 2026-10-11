import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/validators.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/app_textformfield.dart';

@RoutePage()
class SignInScreen extends HookConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formRef = useRef(GlobalKey<FormState>());
    final phoneNumber = useTextEditingController();

    return AppScaffold(
      showAppBar: false,
      child: Form(
        key: formRef.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Values.v24.verticalSpace,
            Text(
              'Welcome back',
              style: context.textTheme.headlineMedium,
            ),
            Values.v16.verticalSpace,
            Text(
              'Enter the Phone Number associated with your Paypadi account',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            PhoneTextField(
              controller: phoneNumber,
              validator: phoneNumberValidator,
            ),
            Values.v16.verticalSpace,
            FilledButton(
              onPressed: () => signin(ref, phoneNumber.text, formRef.value),
              child: const Text('Continue'),
            ),
            const Spacer(flex: 6),
          ],
        ),
      ),
    );
  }

  Future<void> signin(
    WidgetRef ref,
    String phoneNumber,
    GlobalKey<FormState> form,
  ) async {
    if (!(form.currentState?.validate() ?? false)) return;

    // Notification setup is best-effort: if it fails, the user can still
    // sign in. Before, an error here stopped them reaching the password
    // screen.
    unawaited(
      ref
          .read(notificationsServiceProvider)
          .initialize()
          .catchError(
            (Object error, StackTrace stack) =>
                debugLogger.error('Notification setup failed', error, stack),
          ),
    );
    await ref
        .read(appRouterProvider)
        .push(EnterPasswordRoute(phoneNumber: phoneNumber));
  }
}
