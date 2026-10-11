import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show HookConsumerWidget, WidgetRef;
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/gen/colors.gen.dart';

class AppPinIndicator extends HookConsumerWidget {
  const AppPinIndicator({
    required this.controller,
    super.key,
    this.pinLength = 4,
  });

  final int pinLength;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(controller);

    final primaryColor = ref.watch(appPrimaryColorProvider);
    final filledCount = controller.text.length.clamp(Values.zero, pinLength);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < pinLength; i++)
          Padding(
            padding: EdgeInsets.only(
              right: i == pinLength - 1 ? Values.zero : Values.v16,
            ),
            child: AnimatedContainer(
              height: Values.v16,
              width: Values.v16,
              duration: Durations.medium4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filledCount ? primaryColor : AppColors.white,
                border: Border.all(color: primaryColor),
              ),
            ),
          ),
      ],
    );
  }
}
