import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/src/features/settings/widgets/setting_tile.dart';
import 'package:paypadi/src/shared/widgets/app_scaffold.dart';

// import 'package:icons_plus/icons_plus.dart' show Iconsax;

@RoutePage()
class SupportScreen extends HookConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Help & Support',
      child: SettingTile(
        name: 'FAQs',
        icon: AppAssets.icons.icHelpAndSupport.svg(),
      ),
    );
  }
}
