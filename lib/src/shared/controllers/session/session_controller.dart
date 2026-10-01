import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/repositories/session/i_session_repository.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/helpers.dart' show jwtExpiry;
import 'package:paypadi/src/features/authentication/controller/authentication_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  late final ISessionRepository _repository;

  bool _isRefreshing = false;
  // The buffer is how much "safety time" we want left before making the call.
  // Token lifespan (60m) - Buffer (5m) = Timer waits 55 minutes.
  static const Duration _refreshBuffer = Duration(minutes: 5);

  @override
  FutureOr<void> build() {
    _repository = ref.watch(sessionRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);

    unawaited(_scheduleSmartRefresh());

    ref.onDispose(() {
      _cancelTimer();
      WidgetsBinding.instance.removeObserver(this);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_scheduleSmartRefresh());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _cancelTimer();
    }
  }

  void _cancelTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _scheduleSmartRefresh() async {
    _cancelTimer();

    final DateTime now = DateTime.now().toUtc();

    // 1. FIRST DEFENSE: Check if the Refresh Token (24 hours) is completely dead.
    // If it is, log the user out instantly without hitting the backend.
    final int? refreshExpiresTimestamp = await ref
        .read(secureCacheProvider)
        .get<int?>(CacheKeys.refreshTokenExpiry);

    if (refreshExpiresTimestamp != null) {
      final DateTime refreshExpirationDate =
          DateTime.fromMillisecondsSinceEpoch(
            refreshExpiresTimestamp * 1000,
            isUtc: true,
          );

      if (refreshExpirationDate.isBefore(now)) {
        debugLogger.info('Refresh token expired (24h passed). Forcing logout.');
        unawaited(ref.read(authenticationControllerProvider.notifier).logout());
        return;
      }
    }

    // 2. SECOND DEFENSE: Check the Access Token (1 hour).
    final int? accessExpiresTimestamp = await ref
        .read(secureCacheProvider)
        .get<int?>(CacheKeys.accessTokenExpiry);

    if (accessExpiresTimestamp == null) {
      return;
    }

    final DateTime accessExpirationDate = DateTime.fromMillisecondsSinceEpoch(
      accessExpiresTimestamp * 1000,
      isUtc: true,
    );

    final Duration timeRemaining = accessExpirationDate.difference(now);

    if (timeRemaining <= _refreshBuffer) {
      // Less than 5 minutes left (or already expired). Refresh immediately.
      await _handleTokenRefresh();
    } else {
      // Token is healthy. Wait for (Time Remaining - 5 Minutes).
      final Duration durationUntilRefresh = timeRemaining - _refreshBuffer;
      _refreshTimer = Timer(
        durationUntilRefresh,
        () => unawaited(_handleTokenRefresh()),
      );
    }
  }

  Future<void> _handleTokenRefresh() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    try {
      await refreshToken();
    } on Exception catch (e, stackTrace) {
      final AppException exception = AppException.handleException(
        e,
        stackTrace,
      );

      if (_isSessionExpiredError(exception)) {
        unawaited(ref.read(authenticationControllerProvider.notifier).logout());
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Only a rejected refresh token ends the session: the backend answers 401
  /// (`token_not_valid`) for an expired or revoked one. A 400 means a
  /// malformed request, and network or parsing failures say nothing about
  /// the session, so the user stays signed in for the next attempt.
  bool _isSessionExpiredError(AppException exception) {
    if (exception is ServerException) {
      return exception.maybeMap(
        unauthorizedRequest: (_) => true,
        forbiddenRequest: (_) => true,
        orElse: () => false,
      );
    }

    return false;
  }

  Future<void> refreshToken() async {
    final String? refreshTokenValue = await ref
        .read(secureCacheProvider)
        .get<String?>(CacheKeys.refreshToken);

    if (refreshTokenValue != null) {
      final result = await _repository.refreshTokens(refreshTokenValue);

      await result.fold(
        (success) async {
          final session = success.data;
          final cache = ref.read(secureCacheProvider);

          // Expiries aren't in the response; read them from the tokens.
          final int? accessExpiry =
              session.accessTokenExpiry ?? jwtExpiry(session.accessToken);

          // Without rotation the backend sends no new refresh token, so the
          // current one and its expiry stay as they are.
          final String? rotatedRefresh = switch (session.refreshToken) {
            final token? when token.isNotEmpty => token,
            _ => null,
          };
          final int? refreshExpiry = rotatedRefresh == null
              ? null
              : session.refreshTokenExpiry ?? jwtExpiry(rotatedRefresh);

          await Future.wait([
            cache.save(key: CacheKeys.accessToken, value: session.accessToken),
            // Clear an expiry we can't read rather than keep the old, past
            // one, which would trigger another refresh straight away.
            if (accessExpiry != null)
              cache.save(key: CacheKeys.accessTokenExpiry, value: accessExpiry)
            else
              cache.remove(CacheKeys.accessTokenExpiry),
            if (rotatedRefresh != null) ...[
              cache.save(key: CacheKeys.refreshToken, value: rotatedRefresh),
              if (refreshExpiry != null)
                cache.save(
                  key: CacheKeys.refreshTokenExpiry,
                  value: refreshExpiry,
                )
              else
                cache.remove(CacheKeys.refreshTokenExpiry),
            ],
          ]);

          unawaited(_scheduleSmartRefresh());
        },
        (failure) => throw failure,
      );
    } else {
      throw const ServerException.unauthorizedRequest('No refresh token found');
    }
  }
}
