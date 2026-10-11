import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/app/session/session_unlocked.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/utils/constants.dart';

/// What a protected route may show, given the stored session and whether
/// the user has unlocked the app since it started.
enum SessionAccess {
  /// The session is alive and the user has unlocked the app.
  allowed,

  /// The session is alive but the user hasn't unlocked yet: send them to the
  /// quick unlock (biometrics or password) before anything protected.
  locked,

  /// No session, or its refresh token has expired: full sign-in needed.
  signedOut,
}

SessionAccess sessionAccess({
  required String? refreshToken,
  required int? refreshExpiry,
  required bool unlocked,
  DateTime? now,
}) {
  if (refreshToken == null || refreshExpiry == null) {
    return SessionAccess.signedOut;
  }
  final expiresAt = DateTime.fromMillisecondsSinceEpoch(
    refreshExpiry * 1000,
    isUtc: true,
  );
  if (!expiresAt.isAfter((now ?? DateTime.now()).toUtc())) {
    return SessionAccess.signedOut;
  }
  return unlocked ? SessionAccess.allowed : SessionAccess.locked;
}

class AuthenticationGuard extends AutoRouteGuard {
  const AuthenticationGuard(this.ref);
  final Ref ref;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final cache = ref.read(secureCacheProvider);
    final access = sessionAccess(
      refreshToken: await cache.get<String?>(CacheKeys.refreshToken),
      refreshExpiry: await cache.get<int?>(CacheKeys.refreshTokenExpiry),
      // A valid stored session isn't enough: without this a protected route
      // opened directly (a deep link, a notification) skipped the unlock.
      unlocked: ref.read(sessionUnlockedProvider),
    );

    switch (access) {
      case SessionAccess.allowed:
        resolver.next();
      case SessionAccess.locked:
        unawaited(router.replace(const LoginRoute()));
        resolver.next(false);
      case SessionAccess.signedOut:
        unawaited(router.replace(const SignInRoute()));
        resolver.next(false);
    }
  }
}

class LandingPageGuard extends AutoRouteGuard {
  const LandingPageGuard(this.ref);
  final Ref ref;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final String? refreshToken = await ref
        .read(secureCacheProvider)
        .get<String?>(CacheKeys.refreshToken);

    // 1. Completely new or logged-out user (No token at all)
    // Allow them to proceed normally to OnboardingRoute
    if (refreshToken == null) {
      resolver.next();
      return;
    }

    // 2. User has a session. Check if the 24-hour Refresh Token is dead.
    final int? refreshExpiresTimestamp = await ref
        .read(secureCacheProvider)
        .get<int?>(CacheKeys.refreshTokenExpiry);

    // Default to dead for security if the timestamp is missing
    bool isSessionDead = true;

    if (refreshExpiresTimestamp != null) {
      final DateTime refreshExpirationDate =
          DateTime.fromMillisecondsSinceEpoch(
            refreshExpiresTimestamp * 1000,
            isUtc: true,
          );

      // Check if the current time has passed the 24-hour limit
      isSessionDead = refreshExpirationDate.isBefore(DateTime.now().toUtc());
    }

    // 3. Route based on the true session state
    if (isSessionDead) {
      // 24 hours passed. Force full login (Phone + Password).
      unawaited(router.replace(const SignInRoute()));
    } else {
      // Within 24 hours. Send to quick unlock (PIN/Biometrics).
      // The SessionController will seamlessly refresh the 1-hour access token in the background.
      unawaited(router.replace(const LoginRoute()));
    }

    // Abort the original Onboarding navigation request since we are redirecting
    resolver.next(false);
  }
}

class DriverAccountGuard extends AutoRouteGuard {
  const DriverAccountGuard(this.ref);
  final Ref ref;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final cache = await ref.read(localCacheProvider.future);
    final needsVehicleInfo =
        await cache.get<bool>(CacheKeys.driverNeedsVehicleInfo) ?? false;

    if (needsVehicleInfo) {
      unawaited(router.replace(const VehicleInformationRoute()));
      resolver.next(false);
      return;
    }

    resolver.next();
  }
}
