import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/features/settings/widgets/setting_tile.dart';
import 'package:paypadi/gen/assets.gen.dart';
import 'package:paypadi/shared/extensions/themed_svg.dart';
import 'package:paypadi/shared/widgets/app_scaffold.dart';

@RoutePage()
class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enablePush = useState<bool>(false);
    final enableEmail = useState<bool>(false);

    return AppScaffold(
      title: 'Notifications',
      child: Column(
        children: [
          SettingTile.switchTile(
            name: 'Push Notification',
            icon: AppAssets.icons.icPushNotification.themed(context),
            switchValue: enablePush.value,
            onChanged: (value) {
              enablePush.value = value;
            },
          ),
          SettingTile.switchTile(
            name: 'Email Notification',
            icon: AppAssets.icons.icEmailNotification.themed(context),
            switchValue: enableEmail.value,
            onChanged: (value) {
              enableEmail.value = value;
            },
          ),
        ],
      ),
    );
  }
}
