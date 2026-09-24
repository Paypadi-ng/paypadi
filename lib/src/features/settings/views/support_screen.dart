import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// import 'package:icons_plus/icons_plus.dart' show Iconsax;

@RoutePage()
class SupportScreen extends HookConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    throw UnimplementedError();
    // return const AppScaffold(
    //   title: 'Help & Support',
    //   child: SettingTile(name: 'FAQs', icon: Iconsax.support_outline),
    // );
  }
}
