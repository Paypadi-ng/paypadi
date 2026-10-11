import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart' show appPrimaryColorProvider;
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/features/authentication/controllers/authentication_controller.dart';
import 'package:paypadi/features/authentication/widgets/pincode_field.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

@RoutePage()
class OtpScreen extends HookConsumerWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formRef = useRef(GlobalKey<FormState>());
    final resendRecognizer = useMemoized(TapGestureRecognizer.new);
    final otpCode = useTextEditingController();
    final phoneNumber = ref.watch(
      authenticationPayloadProvider,
    )['phone_number'];

    useEffect(() {
      Timer? resendTimer;
      bool hasSentCode = false;

      resendRecognizer.onTap = () async {
        // Guard against multiple taps
        if (hasSentCode) return;

        hasSentCode = true;

        await ref
            .read(authenticationControllerProvider.notifier)
            .requestForOtp();

        resendTimer = Timer(const Duration(seconds: 60), () {
          hasSentCode = false;
        });
      };

      return () {
        resendTimer?.cancel();
        resendRecognizer.dispose();
      };
    }, const []);

    ref.listen(authenticationControllerProvider, (previous, current) {
      current.when(
        data: (d) {
          ref.dismissLoading();
          otpCode.clear();
        },
        error: (e, st) {
          ref.dismissLoading();
          ref.showExceptionMessage(e, st);
          otpCode.clear();
        },
        loading: () => ref.showLoading(),
      );
    });

    return AppScaffold(
      child: Form(
        key: formRef.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Values.v32.verticalSpace,
            Text(
              'OTP\nverification',
              style: context.textTheme.headlineMedium,
            ),
            Values.v16.verticalSpace,
            Text(
              'Kindly provide the verification code '
              'sent to your ${obfuscatePhoneNumber(phoneNumber as String)}',
              style: context.textTheme.bodyLarge,
            ),
            Values.v24.verticalSpace,
            Center(
              child: PinCodeField(controller: otpCode),
            ),
            Values.v12.verticalSpace,
            Center(
              child: RichText(
                text: TextSpan(
                  text: 'Didn’t get a code? ',
                  style: context.textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Send again',
                      recognizer: resendRecognizer,
                      style: context.textTheme.bodySmall?.copyWith(
                        letterSpacing: 0.5,
                        decoration: TextDecoration.underline,
                        color: ref.watch(appPrimaryColorProvider),
                        decorationColor: ref.watch(appPrimaryColorProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Values.v24.verticalSpace,
            FilledButton(
              onPressed: () => verifyOtp(ref, otpCode.text, formRef.value),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> verifyOtp(
    WidgetRef ref,
    String otpCode,
    GlobalKey<FormState> form,
  ) async {
    if (!(form.currentState?.validate() ?? false)) return;

    await ref
        .read(authenticationControllerProvider.notifier)
        .verifyOtpCode(otpCode);
  }
}
