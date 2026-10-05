import 'dart:math' show min;

import 'package:paypadi/core/api/exceptions/server_exception.dart';

/// Retry policy for providers whose build() can fail with an API error.
///
/// Riverpod retries a failed build automatically. That helps with failures
/// that can clear up on their own (timeouts, no connection, 5xx), but a 4xx
/// or a response that doesn't parse fails the same way every time, and
/// while retrying the provider stays loading, so its screen never shows the
/// error. Those aren't retried.
///
/// Otherwise this matches Riverpod's default: up to 10 retries, starting at
/// 200ms and doubling up to 6.4s.
Duration? retryTransientFailures(int retryCount, Object error) {
  if (retryCount >= 10 || !_isTransient(error)) return null;
  return Duration(milliseconds: min(200 * (1 << retryCount), 6400));
}

bool _isTransient(Object error) => switch (error) {
  final ServerException exception => exception.maybeMap(
    requestTimeout: (_) => true,
    sendTimeout: (_) => true,
    receiveTimeout: (_) => true,
    noInternetConnection: (_) => true,
    internalServerError: (_) => true,
    badGateway: (_) => true,
    serviceUnavailable: (_) => true,
    orElse: () => false,
  ),
  _ => false,
};
