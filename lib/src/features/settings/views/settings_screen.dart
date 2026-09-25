import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/gen/colors.gen.dart';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:paypadi/src/features/settings/controller/settings_controller.dart';
import 'package:paypadi/src/features/settings/widgets/setting_tile.dart';
import 'package:paypadi/src/shared/controllers/app_version/app_version_controller.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

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
            icon: AppAssets.icons.icProfile.svg(),
            onTap: () => ref.read(appRouterProvider).push(const ProfileRoute()),
          ),
          SettingTile(
            name: 'Notification Preferences',
            icon: AppAssets.icons.icNotificationPreferences.svg(),
            onTap: () =>
                ref.read(appRouterProvider).push(const NotificationsRoute()),
          ),
          SettingTile(
            name: 'Change Password',
            showTrailing: false,
            icon: AppAssets.icons.icChangePassword.svg(),
            onTap: () =>
                ref.read(appRouterProvider).push(const ChangePasswordRoute()),
          ),
          SettingTile(
            name: 'Change Pin',
            showTrailing: false,
            icon: AppAssets.icons.icChangePin.svg(),
            onTap: () =>
                ref.read(appRouterProvider).push(const ChangePinRoute()),
          ),
          SettingTile(
            name: 'Referral',
            showTrailing: false,
            icon: AppAssets.icons.icReferral.svg(),
            onTap: () =>
                ref.read(appRouterProvider).push(const ReferralRoute()),
          ),
          SettingTile(
            name: 'Theme',
            icon: AppAssets.icons.icTheme.svg(),
            onTap: () =>
                ref.read(appRouterProvider).push(const ChangeThemeRoute()),
          ),
          settingsState.maybeWhen(
            data: (state) {
              return Column(
                children: [
                  SettingTile.switchTile(
                    name: 'Enable Biometrics',
                    icon: AppAssets.icons.icBiometrics.svg(),
                    switchValue: state.biometricsIsEnabled,
                    onChanged: (value) async {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .enableBiometrics(biometrics: value);
                    },
                  ),
                  SettingTile.switchTile(
                    name: 'Dark Mode',
                    icon: AppAssets.icons.icDarkMode.svg(),
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
            name: 'Help & Support',
            icon: AppAssets.icons.icHelpAndSupport.svg(),
            onTap: () => ref.read(appRouterProvider).push(const SupportRoute()),
          ),
          SettingTile(
            name: 'Legal & Policies',
            icon: AppAssets.icons.icLegalAndPolicies.svg(),
            onTap: () => ref.read(appRouterProvider).push(LegalRoute()),
          ),
          SettingTile(
            name: 'Log out',
            showTrailing: false,
            icon: AppAssets.icons.icLogout.svg(),
            onTap: () =>
                ref.read(authenticationControllerProvider.notifier).logout(),
          ),

          Text(
            'App Version: ${appVersion.value?.version}',
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.grey400,
            ),
          ),
          Values.v24.verticalSpace,
        ],
      ),
    );
  }
}
