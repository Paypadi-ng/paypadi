import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppEnvironment {
  static String? flavor = appFlavor;
  static String backendApiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
  );
  static String sentryDsn = const String.fromEnvironment('SENTRY_DSN');

  /// Where this build is deployed (dev / staging / prod). Staging builds use
  /// the prod flavor, so this is what keeps their Sentry events separate.
  static String? deployEnvironment = const bool.hasEnvironment('DEPLOY_ENV')
      ? const String.fromEnvironment('DEPLOY_ENV')
      : flavor;

  static bool get isProd => flavor == 'prod';

  static bool get isDev => flavor == 'dev';

  static Color get color => switch (flavor) {
    'dev' => Colors.red,
    'prod' => Colors.transparent,
    _ => const Color(0xA0B71C1C),
  };
}
