import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.dart' show AppRouter;
import 'package:paypadi/app/theme.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/shared/controllers/app_loading_controller.dart';
import 'package:paypadi/shared/controllers/settings_controller.dart';
import 'package:paypadi/shared/widgets/loading_indicator.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:toastification/toastification.dart';

class PayPadi extends ConsumerWidget {
  const PayPadi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppRouter router = ref.watch(appRouterProvider);
    final AppTheme appTheme = ref.watch(appThemeProvider);
    final darkMode =
        ref.watch(settingsControllerProvider).value?.darkModeIsEnabled ?? false;

    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      designSize: appDesignSize,
      builder: (context, _) {
        return ToastificationWrapper(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: appTheme.theme(),
            darkTheme: appTheme.darkTheme(),
            themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
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
            // Skeletons follow the app's theme, not the phone's.
            builder: (context, child) => SkeletonizerConfig(
              data: SkeletonizerConfigData(
                brightness: darkMode ? Brightness.dark : Brightness.light,
              ),
              child: AppLoadingOverlay(child: child!),
            ),
          ),
        );
      },
    );
  }
}
