import 'dart:io' show Platform;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart'
    show appRouterProvider, localCacheProvider;
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

@RoutePage()
class BiometricAuthenticationScreen extends ConsumerWidget {
  const BiometricAuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      // bottomPadding: Values.v32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Values.v32.verticalSpace,
          SizedBox(
            width: Values.v84,
            height: Values.v84,
            child: Platform.isIOS
                ? AppAssets.icons.icFaceId.svg()
                : AppAssets.icons.icFingerprint.svg(),
          ),
          Values.v24.verticalSpace,
          Text(
            Platform.isIOS ? 'Enable Face ID' : 'Enable Fingerprint',
            style: context.textTheme.headlineMedium,
          ),
          Values.v16.verticalSpace,
          Text(
            Platform.isIOS
                ? 'Use face recognition for a faster and more secure access.'
                : 'Use fingerprint for a faster and more secure access.',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Row(
            spacing: Values.v8,
            children: [
              Flexible(
                child: OutlinedButton(
                  onPressed: () => maybeLater(ref),
                  child: const Text('Maybe Later'),
                ),
              ),
              Flexible(
                child: FilledButton(
                  onPressed: () => enable(ref),
                  child: const Text('Enable'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> maybeLater(WidgetRef ref) async {
    await ref.read(appRouterProvider).replaceAll([const SignInRoute()]);
  }

  Future<void> enable(WidgetRef ref) async {
    final localCache = await ref.read(localCacheProvider.future);
    await localCache.save(key: CacheKeys.biometrics, value: true);
    await ref.read(appRouterProvider).replaceAll([const SignInRoute()]);
  }
}
