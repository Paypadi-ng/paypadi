import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/gen/fonts.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/validators.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/app_textformfield.dart';

@RoutePage()
class CreateAccountScreen extends HookConsumerWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formRef = useRef(GlobalKey<FormState>());
    final signInRecognizer = useMemoized(TapGestureRecognizer.new);
    final phoneNumber = useTextEditingController();

    useEffect(() {
      signInRecognizer.onTap = () =>
          ref.read(appRouterProvider).push(const SignInRoute());
      return signInRecognizer.dispose;
    }, const []);

    ref.listen(authenticationControllerProvider, (previous, current) {
      current.when(
        data: (d) {
          ref.dismissLoading();
          phoneNumber.clear();
        },
        error: (e, st) {
          ref.dismissLoading();
          ref.showExceptionMessage(e, st);
          phoneNumber.clear();
        },
        loading: () => ref.showLoading(),
      );
    });

    return AppScaffold(
      showAppBar: false,
      child: Form(
        key: formRef.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Values.v32.verticalSpace,
            Text(
              'Let’s get\nyou started',
              style: context.textTheme.headlineMedium,
            ),
            Values.v32.verticalSpace,
            PhoneTextField(
              controller: phoneNumber,
              validator: phoneNumberValidator,
            ),
            Values.v16.verticalSpace,
            const _TermsAndPrivacyRichText(),
            Values.v16.verticalSpace,
            FilledButton(
              onPressed: () =>
                  requestForOtp(ref, formRef.value, phoneNumber.text),
              child: const Text('Create Account'),
            ),
            Values.v8.verticalSpace,
            Center(
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontFamily: FontFamily.manrope,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      recognizer: signInRecognizer,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontFamily: FontFamily.manrope,
                        color: ref.watch(appPrimaryColorProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> requestForOtp(
    WidgetRef ref,
    GlobalKey<FormState> form,
    String phoneNumber,
  ) async {
    if (!(form.currentState?.validate() ?? false)) return;

    ref.closeKeyboard();
    ref.read(authenticationPayloadProvider)['phone_number'] = phoneNumber;
    await ref.read(authenticationControllerProvider.notifier).requestForOtp();
  }
}

class _TermsAndPrivacyRichText extends HookConsumerWidget {
  const _TermsAndPrivacyRichText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsRecognizer = useMemoized(TapGestureRecognizer.new);
    final privacyRecognizer = useMemoized(TapGestureRecognizer.new);

    useEffect(() {
      termsRecognizer.onTap = () {
        /* NOTE: open terms */
      };
      privacyRecognizer.onTap = () {
        /* NOTE: open privacy policy */
      };
      return () {
        termsRecognizer.dispose();
        privacyRecognizer.dispose();
      };
    }, const []);

    final primaryColor = ref.watch(appPrimaryColorProvider);
    final style = context.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      fontFamily: FontFamily.manrope,
    );
    final linkedStyle = style?.copyWith(color: primaryColor);

    return RichText(
      text: TextSpan(
        text: 'By proceeding, you agree to our',
        style: style,
        children: [
          TextSpan(
            text: ' Terms of Service ',
            recognizer: termsRecognizer,
            style: linkedStyle,
          ),
          TextSpan(text: 'and ', style: style),
          TextSpan(
            text: 'Privacy Policy',
            recognizer: privacyRecognizer,
            style: linkedStyle,
          ),
        ],
      ),
    );
  }
}
