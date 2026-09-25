import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/repositories/session/i_session_repository.dart';
import 'package:paypadi/core/utils/constants.dart';
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

  bool _isSessionExpiredError(AppException exception) {
    if (exception is ServerException) {
      return exception.maybeMap(
        unauthorizedRequest: (_) => true,
        forbiddenRequest: (_) => true,
        badRequest: (_) => true,
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
          await Future.wait([
            ref
                .read(secureCacheProvider)
                .save(
                  key: CacheKeys.refreshToken,
                  value: success.data.refreshToken,
                ),
            ref
                .read(secureCacheProvider)
                .save(
                  key: CacheKeys.accessToken,
                  value: success.data.accessToken,
                ),
            ref
                .read(secureCacheProvider)
                .save(
                  key: CacheKeys.accessTokenExpiry,
                  value: success.data.accessTokenExpiry,
                ),
            // IMPORTANT: Persist the new Refresh Token Expiry so the 24-hour clock resets
            ref
                .read(secureCacheProvider)
                .save(
                  key: CacheKeys.refreshTokenExpiry,
                  value: success.data.refreshTokenExpiry,
                ),
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
