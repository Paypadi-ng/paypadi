import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:paypadi/config/gen/colors.gen.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/src/shared/controllers/app_loading/app_loading_controller.dart';

class AppLoadingOverlay extends ConsumerWidget {
  const AppLoadingOverlay({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(appLoadingControllerProvider);

    return Stack(
      children: [
        child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const _LoadingBarrier(key: ValueKey('loading'))
              : const SizedBox.shrink(key: ValueKey('idle')),
        ),
      ],
    );
  }
}

class _LoadingBarrier extends ConsumerWidget {
  const _LoadingBarrier({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(appPrimaryColorProvider);

    return AbsorbPointer(
      child: ColoredBox(
        color: AppColors.black.withValues(alpha: .3),
        child: Center(
          child: LoadingAnimationWidget.threeArchedCircle(
            color: primaryColor,
            size: Values.v64,
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends ConsumerWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color primaryColor = ref.watch(appPrimaryColorProvider);

    return Center(
      child: LoadingAnimationWidget.hexagonDots(
        color: primaryColor,
        size: Values.v36,
      ),
    );
  }
}

/// Dismisses the global loading overlay when a screen is popped.
///
/// Screens show the overlay while a request runs and dismiss it when the
/// request settles, from a listener that lives as long as the screen. If the
/// user leaves the screen first (the Android back button or the iOS back
/// swipe still work under the overlay), that listener is gone and the
/// overlay would block the whole app.
class DismissLoadingOnPop extends NavigatorObserver {
  DismissLoadingOnPop(this._dismiss);

  final VoidCallback _dismiss;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Navigator callbacks can run while widgets are building, when
    // providers must not change; dismiss once that has finished.
    scheduleMicrotask(_dismiss);
  }
}
