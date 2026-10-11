import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppEnvironment {
  static String? flavor = appFlavor;
  static String backendApiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
  );
  static String sentryDsn = const String.fromEnvironment('SENTRY_DSN');

  static bool get isProd => flavor == 'prod';

  static bool get isStaging => flavor == 'staging';

  static bool get isDev => flavor == 'dev';

  static Color get color => switch (flavor) {
    'dev' => Colors.red,
    'staging' => Colors.orange,
    'prod' => Colors.transparent,
    _ => const Color(0xA0B71C1C),
  };
}
