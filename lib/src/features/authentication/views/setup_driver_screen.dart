import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart' show Values;
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/validators.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/app_textformfield.dart';

@RoutePage()
class SetupDriverScreen extends HookConsumerWidget {
  const SetupDriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = useTextEditingController();
    final surname = useTextEditingController();
    final email = useTextEditingController();
    final referralCode = useTextEditingController();
    final formRef = useRef(GlobalKey<FormState>());

    return AppScaffold(
      makeScrollable: true,
      appBar: AppBar(
        title: Text(
          'Step 1 out of 5',
          style: context.textTheme.titleSmall,
        ),
        centerTitle: true,
      ),
      child: Form(
        key: formRef.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Values.v32.verticalSpace,
            Text(
              'Set up your account',
              style: context.textTheme.headlineMedium,
            ),
            Values.v16.verticalSpace,
            Text(
              'Kindly provide the details below to help give you the best experience.',
              style: context.textTheme.bodyMedium,
            ),
            Values.v32.verticalSpace,
            AppTextformfield(
              title: 'First Name',
              hint: 'Enter first name',
              controller: firstName,
              validator: nameValidator,
            ),
            AppTextformfield(
              title: 'Surname',
              hint: 'Enter surname',
              controller: surname,
              validator: nameValidator,
            ),
            AppTextformfield(
              title: 'Email (Optional)',
              hint: 'Enter your email',
              controller: email,
            ),
            AppTextformfield(
              title: 'Referral Code (Optional)',
              hint: 'Enter referral code',
              controller: referralCode,
            ),
            Values.v24.verticalSpace,
            FilledButton(
              onPressed: () => submit(
                ref,
                firstName.text,
                surname.text,
                email.text,
                referralCode.text,
                formRef.value,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void submit(
    WidgetRef ref,
    String firstName,
    String lastName,
    String email,
    String referralCode,
    GlobalKey<FormState> form,
  ) {
    if (!(form.currentState?.validate() ?? false)) return;

    Map<String, dynamic> payloadBuilder = ref.read(
      authenticationPayloadProvider,
    );

    if (referralCode.isNotEmpty) {
      payloadBuilder['referred_by'] = referralCode;
    }
    payloadBuilder
      ..['first_name'] = firstName
      ..['last_name'] = lastName
      ..['email'] = email;

    unawaited(ref.read(appRouterProvider).push(CreatePasswordRoute()));
  }
}
