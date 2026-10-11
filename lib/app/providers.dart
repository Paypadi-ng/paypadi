import 'dart:ui' show Color;

import 'package:paypadi/app/router/router.dart' show AppRouter;
import 'package:paypadi/app/session/session_controller.dart';
import 'package:paypadi/app/theme.dart' show AppTheme;
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/constants.dart' show availableColors;
import 'package:paypadi/src/shared/controllers/app_color/app_color_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overrides every app ProviderContainer needs: they connect lower layers to
/// app-level providers those layers can't import.
final appProviderOverrides = [
  sessionRenewerProvider.overrideWith(
    (ref) =>
        () => ref.read(sessionControllerProvider.notifier).renewSession(),
  ),
];

// =============================================================================
// Theme & UI Configurations
// =============================================================================

@Riverpod(keepAlive: true)
Color appPrimaryColor(Ref ref) {
  // Watch the async state of the color index
  final colorIndexAsync = ref.watch(colorIndexProvider);

  // Map the index to the color, defaulting to the first color if loading/error
  return colorIndexAsync.maybeWhen(
    data: (index) => availableColors[index],
    orElse: () => availableColors[0],
  );
}

@Riverpod(keepAlive: true)
AppTheme appTheme(Ref ref) {
  return AppTheme(primary: ref.watch(appPrimaryColorProvider));
}

@Riverpod(keepAlive: true)
AppRouter appRouter(Ref ref) {
  return AppRouter(ref: ref);
}
