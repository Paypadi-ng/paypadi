/// An enum to control Sentry logging thresholds
enum SeverityLevel { debug, info, warning, error, fatal }

abstract class MonitoringService {
  Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? context, // e.g. 'AuthInterceptor', 'PaymentRepo'
    Map<String, dynamic>? extras,
    SeverityLevel level,
  });

  Future<void> captureMessage(
    String message, {
    String? context,
    Map<String, dynamic>? extras,
    SeverityLevel level,
  });

  Future<void> setUser(MonitoringUser? user); // null = clear on logout

  Future<void> addBreadcrumb({
    required String message,
    String? category, // e.g. 'navigation', 'auth', 'network'
    Map<String, dynamic>? data,
  });
}

class MonitoringUser {
  const MonitoringUser({required this.id, this.email, this.username});
  final String id;
  final String? email;
  final String? username;
}
