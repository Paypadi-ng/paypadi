import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';

typedef ExceptionLogger =
    Future<void> Function(
      // for severity/context/extras metadata
      AppException converted,
      // the real exception e.g. DioException, SocketException, etc.
      Object? original,
      StackTrace stackTrace,
    );

abstract class AppException implements Exception {
  factory AppException.handleException(
    dynamic exception, [
    StackTrace? stackTrace,
  ]) {
    late final AppException appException;

    try {
      appException = switch (exception) {
        final AppException e => e,

        // --- HTTP / DIO EXCEPTIONS ---
        final DioException e => switch (e.type) {
          DioExceptionType.cancel => const ServerException.requestCancelled(),
          DioExceptionType.connectionTimeout =>
            const ServerException.requestTimeout(),
          DioExceptionType.sendTimeout => const ServerException.sendTimeout(),
          DioExceptionType.receiveTimeout =>
            const ServerException.receiveTimeout(),
          DioExceptionType.badCertificate =>
            const ServerException.internalServerError(),
          DioExceptionType.badResponse =>
            e.response != null
                ? ServerException.handleResponse(e.response)
                : const ServerException.internalServerError(),
          DioExceptionType.connectionError =>
            const ServerException.noInternetConnection(),
          DioExceptionType.unknown =>
            const ServerException.serviceUnavailable(),
        },
        TimeoutException _ => const ServerException.requestTimeout(),
        final HttpException he => ClientException(message: he.message),
        HandshakeException _ => const ServerException.internalServerError(),
        final WebSocketException we => ClientException(message: we.message),

        // --- DART TYPE / FORMAT ERRORS ---
        final TypeError te => ClientException(
          message: 'Invalid response format from server.',
          cause: te,
        ),
        final NoSuchMethodError ne => ClientException(
          message: 'Invalid response shape from server.',
          cause: ne,
        ),
        final FormatException fe => ClientException(message: fe.message),

        // --- NATIVE / SYSTEM ERRORS ---
        final Error e => throw e,
        final PlatformException pe => ClientException(
          message: '${pe.code}: ${pe.message ?? pe.details?.toString() ?? ''}',
        ),
        final SocketException se => ClientException(message: se.message),

        // --- FALLBACKS ---
        final Exception ex => ClientException(
          message: ex.toString(),
          cause: ex,
        ),
        Object() => ClientException(message: '$exception'),
        null => const ClientException(message: 'Null exception'),
      };
    } on Exception catch (ex, st) {
      appException = ClientException(
        message: ex.toString(),
        cause: ex,
        stackTrace: st,
      );
    }

    if (appException.isReportable) {
      unawaited(
        logger?.call(appException, exception, stackTrace ?? StackTrace.current),
      );
    }

    return appException;
  }

  const AppException();

  static ExceptionLogger? logger;

  SeverityLevel get monitoringSeverity;

  String get monitoringContext;

  Map<String, dynamic> get monitoringExtras;

  /// Forces all domain exceptions to expose a base message.
  /// This ensures custom hardware exceptions can pass their message to the UI.
  String get message;

  ///  A getter to explicitly tell the logger if this should go to Sentry.
  /// (e.g., Return false for network timeouts or user cancellations).
  bool get isReportable =>
      monitoringSeverity == SeverityLevel.error ||
      monitoringSeverity == SeverityLevel.fatal;

  static String getExceptionMessage(Exception exception) {
    return switch (exception) {
      final ServerException serverEx => serverEx.map(
        requestCancelled: (_) =>
            'Your request was cancelled. Please try again.',
        requestTimeout: (_) =>
            'Connection timed out. Please check your internet connection and try again.',
        sendTimeout: (_) =>
            'Request is taking too long to send. Please try again.',
        receiveTimeout: (_) =>
            'Server is taking too long to respond. Please try again later.',
        badRequest: (e) =>
            e.reason ??
            'Invalid request. Please check your input and try again.',
        unauthorizedRequest: (e) =>
            e.reason ?? 'You are not authorized to perform this action.',
        forbiddenRequest: (e) =>
            e.reason ?? 'You are forbidden from performing this action.',
        methodNotAllowed: (e) =>
            e.reason ?? 'The requested method is not allowed.',
        notAcceptable: (e) =>
            e.reason ?? 'The requested resource is not acceptable.',
        conflict: (e) =>
            e.reason ?? 'The request conflicts with the current state.',
        unsupportedMediaType: (e) => e.reason ?? 'Unsupported media type.',
        tooManyRequests: (e) {
          final suffix = e.retryAfter != null
              ? ' Try again in ${e.retryAfter!.inSeconds} seconds.'
              : ' Please try again later.';
          return (e.reason ?? 'Too many requests.') + suffix;
        },
        notImplemented: (e) => e.reason ?? 'This feature is not yet available.',
        badGateway: (e) => e.reason ?? 'Bad gateway. Please try again later.',
        notFound: (e) => e.reason ?? 'The requested resource was not found.',
        unprocessableEntity: (e) =>
            e.reason ??
            'Unable to process your request. Please check your input.',
        internalServerError: (_) =>
            'Something went wrong on our end. Please try again later.',
        serviceUnavailable: (_) =>
            'Service is currently unavailable. Please try again later.',
        noInternetConnection: (_) =>
            'No internet connection. Please check your network and try again.',
        defaultError: (e) =>
            e.error ?? 'An unexpected error occurred. Please try again.',
      ),

      final ClientException clientEx => _getClientExceptionMessage(clientEx),
      //  If it's a custom AppException (like ObdConnectionDroppedException),
      // we extract its native message instead of defaulting to a generic error!
      final AppException appEx => appEx.message,

      _ => 'Something went wrong. Please try again later.',
    };
  }

  static String _getClientExceptionMessage(ClientException ex) {
    final msg = ex.message.toLowerCase();

    if (msg.contains('network') || msg.contains('connection')) {
      return 'Network connection problem. Please check your internet and try again.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('certificate') || msg.contains('ssl')) {
      return 'Security connection error. Please try again later.';
    }
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Permission denied. Please check your settings.';
    }
    if (msg.contains('format') || msg.contains('parse')) {
      return 'Data format error. Please try again.';
    }

    return ex.message.isNotEmpty
        ? ex.message
        : 'An error occurred. Please try again later.';
  }
}
