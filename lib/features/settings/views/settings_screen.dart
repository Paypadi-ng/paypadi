import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/app/session/session_controller.dart';
import 'package:paypadi/app/theme.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/features/settings/widgets/setting_tile.dart';
import 'package:paypadi/gen/assets.gen.dart';
import 'package:paypadi/shared/controllers/app_version_controller.dart';
import 'package:paypadi/shared/controllers/settings_controller.dart';
import 'package:paypadi/shared/extensions/themed_svg.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

@RoutePage()
class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(appVersionControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);

    return AppScaffold(
      showAppBar: false,
      makeScrollable: true,
      onRefresh: () => Future.delayed(Durations.medium4),
      padding: EdgeInsets.zero,
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: context.textTheme.headlineSmall?.copyWith(
            letterSpacing: Values.zero,
          ),
        ),
      ),
      child: Column(
        children: [
          SettingTile(
            name: 'Profile',
            icon: AppAssets.icons.icProfile.themed(context),
            onTap: () => ref.read(appRouterProvider).push(const ProfileRoute()),
          ),
          SettingTile(
            name: 'Notification Preferences',
            icon: AppAssets.icons.icNotificationPreferences.themed(context),
            onTap: () =>
                ref.read(appRouterProvider).push(const NotificationsRoute()),
          ),
          SettingTile(
            name: 'Change Password',
            showTrailing: false,
            icon: AppAssets.icons.icChangePassword.themed(context),
            onTap: () =>
                ref.read(appRouterProvider).push(const ChangePasswordRoute()),
          ),
          SettingTile(
            name: 'Change Pin',
            showTrailing: false,
            icon: AppAssets.icons.icChangePin.themed(context),
            onTap: () =>
                ref.read(appRouterProvider).push(const ChangePinRoute()),
          ),
          SettingTile(
            name: 'Referral',
            showTrailing: false,
            icon: AppAssets.icons.icReferral.themed(context),
            onTap: () =>
                ref.read(appRouterProvider).push(const ReferralRoute()),
          ),
          SettingTile(
            name: 'Theme',
            icon: AppAssets.icons.icTheme.themed(context),
            onTap: () =>
                ref.read(appRouterProvider).push(const ChangeThemeRoute()),
          ),
          settingsState.maybeWhen(
            data: (state) {
              return Column(
                children: [
                  SettingTile.switchTile(
                    name: 'Enable Biometrics',
                    icon: const Icon(Icons.fingerprint),
                    switchValue: state.biometricsIsEnabled,
                    onChanged: (value) async {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .enableBiometrics(biometrics: value);
                    },
                  ),
                  SettingTile.switchTile(
                    name: 'Dark Mode',
                    icon: AppAssets.icons.icDarkMode.themed(context),
                    switchValue: state.darkModeIsEnabled,
                    onChanged: (value) async {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .enableDarkMode(darkMode: value);
                    },
                  ),
                ],
              );
            },
            orElse: SizedBox.shrink,
          ),
          SettingTile(
            name: 'FAQs',
            icon: AppAssets.icons.icHelpAndSupport.themed(context),
            onTap: () async =>
                ref.read(urlLauncherProvider).launchWebUrl(appSupportAndFaqs),
          ),
          SettingTile(
            name: 'Legal & Policies',
            icon: AppAssets.icons.icLegalAndPolicies.themed(context),
            onTap: () async =>
                ref.read(urlLauncherProvider).launchWebUrl(appPrivacyPolicy),
          ),
          SettingTile(
            name: 'Log out',
            showTrailing: false,
            icon: AppAssets.icons.icLogout.themed(context),
            onTap: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),

          Text(
            'App Version: ${appVersion.value?.version}',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.palette.grey400,
            ),
          ),
          Values.v24.verticalSpace,
        ],
      ),
    );
  }
}

// final token = await ref
//     .read(notificationsServiceProvider)
//     .getToken();

// token.printLog();
