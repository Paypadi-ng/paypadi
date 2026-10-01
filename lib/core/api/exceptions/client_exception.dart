import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';

base class ClientException extends AppException {
  const ClientException({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final Object? cause;
  final StackTrace? stackTrace;

  @override
  final String message;

  @override
  SeverityLevel get monitoringSeverity => switch (cause) {
    TypeError() => SeverityLevel.error,
    NoSuchMethodError() => SeverityLevel.error,
    _ => SeverityLevel.warning,
  };

  @override
  String get monitoringContext => 'Client';

  @override
  Map<String, dynamic> get monitoringExtras => {
    if (cause != null) 'cause': cause.toString(),
    if (message.isNotEmpty) 'message': message,
  };

  @override
  String toString() => message;
}
