import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart'
    show appPrimaryColorProvider;
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';

class AppKeypad extends ConsumerWidget {
  const AppKeypad({
    required this.controller,
    super.key,
    this.padding,
    this.onSubmit,
    this.keyLength = 4,
    this.showBiometric = false,
    this.onBiometricKeyPressed,
  });

  final TextEditingController controller;
  final int keyLength;
  final bool showBiometric;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onBiometricKeyPressed;
  final ValueChanged<String>? onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: kAppKeyPadKeys.length,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: Values.v24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 36,
      ),
      itemBuilder: (context, index) =>
          _buildKeyButton(context, ref, kAppKeyPadKeys[index]),
    );
  }

  void _onTap(String key) {
    unawaited(HapticFeedback.lightImpact());

    if (showBiometric && key == '.') {
      onBiometricKeyPressed?.call();
      return;
    }

    if (key == 'x') {
      if (controller.text.isNotEmpty) {
        controller.text = controller.text.substring(
          0,
          controller.text.length - 1,
        );
      }
      return;
    }

    if (key != '.' && controller.text.length < keyLength) {
      controller.text += key;
      // Auto-submit when PIN is complete
      if (controller.text.length == keyLength) {
        onSubmit?.call(controller.text);
      }
    }
  }

  Widget _buildKeyButton(BuildContext context, WidgetRef ref, String key) {
    return InkWell(
      onTap: (key == '.' && !showBiometric) ? null : () => _onTap(key),
      customBorder: const CircleBorder(),
      splashColor: ref.watch(appPrimaryColorProvider).withValues(alpha: .1),
      child: Center(
        child: switch (key) {
          'x' => AppAssets.icons.icBackspace.svg(),
          '.' =>
            showBiometric
                ? const Icon(Icons.fingerprint, size: Values.v36)
                : const SizedBox.shrink(),
          _ => Text(
            key,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        },
      ),
    );
  }
}
