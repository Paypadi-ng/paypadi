import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

/// What the app can honestly say about password resets.
///
/// This screen used to say a reset link had been emailed, but nothing was
/// ever sent: the API has no endpoint to reset a password yet. Replace this
/// copy with the real flow once the backend supports one.
const passwordResetUnavailableMessage =
    "Password reset isn't available in the app yet. Please contact Paypadi "
    'support and we will help you get back into your account.';

@RoutePage()
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Values.v24.verticalSpace,
          Text(
            'Forgot your password?',
            style: context.textTheme.headlineSmall,
          ),
          Values.v16.verticalSpace,
          Text(
            passwordResetUnavailableMessage,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
