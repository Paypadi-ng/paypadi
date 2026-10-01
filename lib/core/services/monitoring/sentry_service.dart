import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryMonitoringService implements MonitoringService {
  @override
  Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
    SeverityLevel level = SeverityLevel.error,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) async {
        scope.level = level._toSentry();
        if (context != null) await scope.setTag('context', context);
        if (extras != null) await scope.setContexts('details', extras);
      },
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    String? context,
    Map<String, dynamic>? extras,
    SeverityLevel level = SeverityLevel.info,
  }) async {
    await Sentry.captureMessage(
      message,
      level: level._toSentry(),
      withScope: (scope) async {
        if (context != null) await scope.setTag('context', context);
        if (extras != null) await scope.setContexts('details', extras);
      },
    );
  }

  @override
  Future<void> setUser(MonitoringUser? user) async {
    await Sentry.configureScope((scope) async {
      await scope.setUser(
        user == null
            ? null
            : SentryUser(
                id: user.id,
                email: user.email,
                username: user.username,
              ),
      );
    });
  }

  @override
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category, data: data),
    );
  }
}

extension on SeverityLevel {
  SentryLevel _toSentry() => switch (this) {
    SeverityLevel.debug => SentryLevel.debug,
    SeverityLevel.info => SentryLevel.info,
    SeverityLevel.warning => SentryLevel.warning,
    SeverityLevel.error => SentryLevel.error,
    SeverityLevel.fatal => SentryLevel.fatal,
  };
}
