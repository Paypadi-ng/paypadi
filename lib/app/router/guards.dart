import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';

class AuthenticationGuard extends AutoRouteGuard {
  const AuthenticationGuard(this.ref);
  final Ref ref;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final String? refreshToken = await ref
        .read(secureCacheProvider)
        .get<String?>(CacheKeys.refreshToken);

    final int? refreshExpiresTimestamp = await ref
        .read(secureCacheProvider)
        .get<int?>(CacheKeys.refreshTokenExpiry);

    bool isSessionDead = true;

    if (refreshToken != null && refreshExpiresTimestamp != null) {
      final DateTime refreshExpirationDate =
          DateTime.fromMillisecondsSinceEpoch(
            refreshExpiresTimestamp * 1000,
            isUtc: true,
          );

      if (refreshExpirationDate.isAfter(DateTime.now().toUtc())) {
        isSessionDead = false;
      }
    }

    if (isSessionDead) {
      // 1. Session is completely dead (or missing). Navigate to the sign-in screen.
      unawaited(router.replace(const SignInRoute()));

      // 2. Explicitly abort the pending protected navigation.
      resolver.next(false);
      return;
    }

    // User is authenticated and within their 24-hour window, allow navigation to proceed.
    resolver.next();
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
    // final localCache = await ref.read(localCacheProvider.future);

    // final UserModel? user = await localCache.get(
    //   CacheKeys.user,
    //   (raw) => UserModel.fromJson(raw as Map<String, dynamic>),
    // );

    // if (user != null && user.isDriver == true && user.isApproved == false) {
    //   // Force unapproved drivers to complete their vehicle information
    //   unawaited(router.replace(const VehicleInformationRoute()));
    //   resolver.next(false);
    //   return;
    // }

    // User is either not a driver, or is an approved driver
    resolver.next();
  }
}
