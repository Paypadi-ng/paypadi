import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';

part 'server_exception.freezed.dart';

@freezed
sealed class ServerException extends AppException with _$ServerException {
  const ServerException._() : super();

  const factory ServerException.requestCancelled() = _RequestCancelled;
  const factory ServerException.requestTimeout() = _RequestTimeout;
  const factory ServerException.sendTimeout() = _SendTimeout;
  const factory ServerException.receiveTimeout() = _ReceiveTimeout;
  const factory ServerException.badRequest(String? reason) = _BadRequest;
  const factory ServerException.unauthorizedRequest(String? reason) =
      _UnauthorizedRequest;
  const factory ServerException.forbiddenRequest(String? reason) =
      _ForbiddenRequest;
  const factory ServerException.methodNotAllowed(String? reason) =
      _MethodNotAllowed;
  const factory ServerException.notAcceptable(String? reason) = _NotAcceptable;
  const factory ServerException.unsupportedMediaType(String? reason) =
      _UnsupportedMediaType;

  const factory ServerException.conflict(
    String? reason,
    String? conflictingAssetId,
  ) = _Conflict;

  const factory ServerException.tooManyRequests({
    String? reason,
    Duration? retryAfter,
  }) = _TooManyRequests;

  const factory ServerException.notImplemented(String? reason) =
      _NotImplemented;
  const factory ServerException.badGateway(String? reason) = _BadGateway;
  const factory ServerException.notFound(String? reason) = _NotFound;
  const factory ServerException.unprocessableEntity(String? reason) =
      _UnprocessableEntity;
  const factory ServerException.internalServerError() = _InternalServerError;
  const factory ServerException.serviceUnavailable() = _ServiceUnavailable;
  const factory ServerException.noInternetConnection() = _NoInternetConnection;
  const factory ServerException.defaultError(String? error) = _DefaultError;

  static ServerException handleResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;

    if (statusCode == null) {
      return const ServerException.defaultError(
        'No status code received from server.',
      );
    }

    String? message;
    String? conflictingAssetId;
    final data = response?.data;

    // Read the body defensively: a cast that fails here throws a TypeError,
    // which escapes error handling and leaves the caller stuck loading.
    if (data is Map) {
      message = readableMessage(data['message']);
      conflictingAssetId = switch (data['data']) {
        final Map<Object?, Object?> details =>
          details['document_id']?.toString(),
        _ => null,
      };
    }

    switch (statusCode) {
      case 400:
        return ServerException.badRequest(message);
      case 401:
        return ServerException.unauthorizedRequest(message);
      case 403:
        return ServerException.forbiddenRequest(message);
      case 404:
        return ServerException.notFound(message);
      case 405:
        return ServerException.methodNotAllowed(message);
      case 406:
        return ServerException.notAcceptable(message);
      case 408:
        return const ServerException.requestTimeout();
      case 409:
        return ServerException.conflict(message, conflictingAssetId);
      case 415:
        return ServerException.unsupportedMediaType(message);
      case 422:
        return ServerException.unprocessableEntity(message);
      case 429:
        // Parse Retry-After header (seconds integer form; ignores HTTP-date form).
        final raw = response?.headers.value('Retry-After');
        final seconds = raw != null ? int.tryParse(raw) : null;
        return ServerException.tooManyRequests(
          reason: message,
          retryAfter: seconds != null ? Duration(seconds: seconds) : null,
        );
      case 500:
        return const ServerException.internalServerError();
      case 501:
        return ServerException.notImplemented(message);
      case 502:
        return ServerException.badGateway(message);
      case 503:
        return const ServerException.serviceUnavailable();
      default:
        return ServerException.defaultError(
          'Unrecognised status code: $statusCode',
        );
    }
  }

  /// The first readable message in an error body field: the string itself,
  /// or the first message inside a map or list of field errors, such as
  /// `{"phone_number": ["This field is required."]}`.
  @visibleForTesting
  static String? readableMessage(Object? value) => switch (value) {
    final String text when text.trim().isNotEmpty => text,
    final List<Object?> items =>
      items.map(readableMessage).nonNulls.firstOrNull,
    final Map<Object?, Object?> fields =>
      fields.values.map(readableMessage).nonNulls.firstOrNull,
    _ => null,
  };

  @override
  String get monitoringContext => 'Server';

  @override
  SeverityLevel get monitoringSeverity => map(
    requestCancelled: (_) => SeverityLevel.info,
    requestTimeout: (_) => SeverityLevel.warning,
    sendTimeout: (_) => SeverityLevel.warning,
    receiveTimeout: (_) => SeverityLevel.warning,
    noInternetConnection: (_) => SeverityLevel.info,
    unauthorizedRequest: (_) => SeverityLevel.warning,
    tooManyRequests: (_) => SeverityLevel.warning,
    forbiddenRequest: (_) => SeverityLevel.warning,
    badRequest: (_) => SeverityLevel.warning,
    notFound: (_) => SeverityLevel.warning,
    conflict: (_) => SeverityLevel.warning,
    methodNotAllowed: (_) => SeverityLevel.warning,
    notAcceptable: (_) => SeverityLevel.warning,
    unsupportedMediaType: (_) => SeverityLevel.warning,
    unprocessableEntity: (_) => SeverityLevel.warning,
    notImplemented: (_) => SeverityLevel.warning,
    badGateway: (_) => SeverityLevel.error,
    internalServerError: (_) => SeverityLevel.error,
    serviceUnavailable: (_) => SeverityLevel.error,
    defaultError: (_) => SeverityLevel.error,
  );

  @override
  Map<String, dynamic> get monitoringExtras => map(
    tooManyRequests: (e) => {
      if (e.retryAfter != null) 'retryAfter': e.retryAfter!.inSeconds,
    },
    conflict: (e) => {
      if (e.reason != null) 'reason': e.reason,
      if (e.conflictingAssetId != null)
        'conflictingAssetId': e.conflictingAssetId,
    },
    badRequest: (e) => {'reason': e.reason},
    unprocessableEntity: (e) => {'reason': e.reason},
    unauthorizedRequest: (e) => {'reason': e.reason},
    forbiddenRequest: (e) => {'reason': e.reason},
    notFound: (e) => {'reason': e.reason},
    defaultError: (e) => {'error': e.error},
    requestCancelled: (_) => {},
    requestTimeout: (_) => {},
    sendTimeout: (_) => {},
    receiveTimeout: (_) => {},
    noInternetConnection: (_) => {},
    methodNotAllowed: (_) => {},
    notAcceptable: (_) => {},
    unsupportedMediaType: (_) => {},
    notImplemented: (_) => {},
    badGateway: (_) => {},
    internalServerError: (_) => {},
    serviceUnavailable: (_) => {},
  );

  @override
  String get message => AppException.getExceptionMessage(this);
}
