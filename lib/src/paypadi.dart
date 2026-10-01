import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.dart' show AppRouter;
import 'package:paypadi/config/theme.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/src/shared/controllers/app_loading/app_loading_controller.dart';
import 'package:paypadi/src/shared/widgets/loading_indicator.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:toastification/toastification.dart';

class PayPadi extends ConsumerWidget {
  const PayPadi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppRouter router = ref.watch(appRouterProvider);
    final AppTheme appTheme = ref.watch(appThemeProvider);

    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      designSize: appDesignSize,
      builder: (context, _) {
        return ToastificationWrapper(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: appTheme.theme(),
            routerConfig: router.config(
              navigatorObservers: () {
                return [
                  DismissLoadingOnPop(
                    () => ref
                        .read(appLoadingControllerProvider.notifier)
                        .dismiss(),
                  ),
                  if (kDebugMode) TalkerRouteObserver(debugLogger),
                ];
              },
            ),
            builder: (context, child) => AppLoadingOverlay(child: child!),
          ),
        );
      },
    );
  }
}
