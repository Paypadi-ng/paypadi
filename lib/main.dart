import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/env.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart';
import 'package:paypadi/src/paypadi.dart';
import 'package:paypadi/src/shared/controllers/session/session_controller.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to use other Firebase services (like Firestore) in the background,
  // you must make sure Firebase is initialized inside this isolate first.
  await Firebase.initializeApp();

  // Do not try to update UI or Riverpod providers here.
  // This is strictly for background tasks like logging, updating a local database,
  // or sending a delivery receipt back to your server.
  'Handling a background message: ${message.messageId}'.printLog();
}

Future<void> initializeApp({
  required bool enableMonitoring,
  required FirebaseOptions firebaseConfig,
}) async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    preCacheSVGs(),
    Firebase.initializeApp(options: firebaseConfig),
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    ),
  ]);

  // Register the background handler immediately after Firebase initializes
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (enableMonitoring) {
    await SentryFlutter.init(
      (options) {
        options.debug = kDebugMode;
        options.dsn = AppEnvironment.sentryDsn;
        options.environment = AppEnvironment.flavor;
        options.sendDefaultPii = true;
        // options.enableLogs = true;
        options.tracesSampleRate = 1.0;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
        // options.profilesSampleRate = 1.0;
        // Configure Session Replay
        // options.replay.sessionSampleRate = 0.1;
        // options.replay.onErrorSampleRate = 1.0;
      },
      appRunner: () => _runApp(isMonitored: true),
    );
  } else {
    await _runApp(isMonitored: false);
  }
}

Future<void> _runApp({required bool isMonitored}) async {
  final providerContainer = ProviderContainer(
    observers: [
      if (kDebugMode)
        TalkerRiverpodObserver(
          talker: debugLogger,
          settings: const TalkerRiverpodLoggerSettings(
            printProviderDisposed: true,
          ),
        ),
    ],
  );

  // Initializes SharedPreferencesWithCache and JwtRefreshController
  try {
    await providerContainer.read(sharedPreferencesFutureProvider.future);
    await providerContainer.read(sessionControllerProvider.future);
  } catch (e, stack) {
    debugLogger.error(
      'Failed to initialize SharedPreferencesWithCache',
      e,
      stack,
    );
    // Optionally, handle the error further or rethrow
  }

  if (isMonitored) {
    final monitoring = providerContainer.read(monitoringProvider);

    AppException.logger = (appException, original, stackTrace) async {
      await monitoring.captureException(
        original ?? appException,
        stackTrace: stackTrace,
        level: appException.monitoringSeverity,
        context: appException.monitoringContext,
        extras: appException.monitoringExtras,
      );
    };

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        monitoring.captureException(
          details.exception,
          stackTrace: details.stack,
          context: 'FlutterError',
          level: SeverityLevel.fatal,
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        monitoring.captureException(
          error,
          stackTrace: stack,
          context: 'PlatformDispatcher',
        ),
      );
      return true;
    };
  }

  runApp(
    isMonitored
        ? SentryWidget(
            child: UncontrolledProviderScope(
              container: providerContainer,
              child: const PayPadi(),
            ),
          )
        : UncontrolledProviderScope(
            container: providerContainer,
            child: const PayPadi(),
          ),
  );
}
