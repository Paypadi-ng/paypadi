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
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/features/settings/controller/settings_controller.dart';
import 'package:paypadi/src/shared/widgets/app_avatar.dart';
import 'package:paypadi/src/shared/widgets/app_keypad.dart';
import 'package:paypadi/src/shared/widgets/app_pin_indicator.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';
import 'package:paypadi/src/shared/widgets/loading_indicator.dart';

@RoutePage()
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();
    final settings = ref.watch(settingsControllerProvider);

    ref.listen(authenticationControllerProvider, (previous, current) {
      current.when(
        data: (_) => ref.dismissLoading(),
        error: (e, st) => ref.dismissLoading(),
        loading: () => ref.showLoading(),
      );
    });

    // useMemoized ensures we only trigger this read once when the widget mounts.
    final cacheFuture = useMemoized(
      () => Future.wait([
        ref.read(secureCacheProvider).get<String?>(CacheKeys.email),
        ref.read(secureCacheProvider).get<String?>(CacheKeys.firstName),
        ref.read(secureCacheProvider).get<String?>(CacheKeys.phoneNumber),
      ]),
    );

    // useFuture automatically rebuilds the widget when the future completes.
    final snapshot = useFuture(cacheFuture);

    // Show a blank scaffold or loader while securely reading from the device storage
    if (!snapshot.hasData) {
      return const AppScaffold(
        showAppBar: false,
        child: LoadingIndicator(),
      );
    }

    // 3. Safely unpack the data
    final List<String?> cacheData = snapshot.data!;

    final String firstName = cacheData[1] ?? 'User';
    final String? email = cacheData[0];
    final String? phoneNumber = cacheData[2];

    return AppScaffold(
      showAppBar: false,
      padding: const EdgeInsets.only(top: Values.v24),
      child: Column(
        children: [
          const AppAvatar(radius: Values.v84, imageUrl: kDemoProfilePic),
          Values.v16.verticalSpace,
          Text(
            'Good ${getDayTime()}, $firstName',
            style: context.textTheme.headlineSmall,
          ),
          Values.v24.verticalSpace,
          AppPinIndicator(
            pinLength: passwordPinLength,
            controller: passwordController,
          ),
          const Spacer(flex: 2),
          AppKeypad(
            keyLength: passwordPinLength,
            controller: passwordController,
            showBiometric: settings.value?.biometricsIsEnabled ?? false,
            onBiometricKeyPressed: () => ref
                .read(authenticationControllerProvider.notifier)
                .loginWithBiometrics(),
            onSubmit: (password) {
              if (phoneNumber == null) return;

              unawaited(
                ref
                    .read(authenticationControllerProvider.notifier)
                    .login(phoneNumber, password),
              );
            },
          ),
          const Spacer(),
          Center(
            child: GestureDetector(
              onTap: () {
                if (email == null) return;

                unawaited(
                  ref
                      .read(appRouterProvider)
                      .push(ForgotPasswordRoute(email: email)),
                );
              },
              child: Text(
                'Forgot Password?',
                style: context.textTheme.bodyMedium?.copyWith(
                  letterSpacing: -Values.v1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
