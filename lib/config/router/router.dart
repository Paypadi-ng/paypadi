import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/utils/constants.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter({required this.ref});
  final Ref ref;

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: '/',
      initial: true,
      page: OnboardingRoute.page,
      guards: [LandingPageGuard(ref)],
    ),
    AutoRoute(
      path: '/account',
      page: CreateAccountRoute.page,
    ),
    AutoRoute(
      path: '/login',
      page: LoginRoute.page,
    ),
    AutoRoute(
      path: '/account-role',
      page: AccountRoleRoute.page,
    ),
    AutoRoute(
      path: '/setup-passenger',
      page: SetupPassengerRoute.page,
    ),
    AutoRoute(
      path: '/setup-driver',
      page: SetupDriverRoute.page,
    ),
    AutoRoute(
      path: '/vehicle-information',
      page: VehicleInformationRoute.page,
    ),
    AutoRoute(
      path: '/license',
      page: LicensingRoute.page,
    ),
    AutoRoute(
      path: '/document-upload',
      page: DocumentUploadRoute.page,
    ),
    AutoRoute(
      path: '/payout-account',
      page: PayoutAccountRoute.page,
    ),
    AutoRoute(
      path: '/otp',
      page: OtpRoute.page,
    ),
    AutoRoute(
      path: '/password',
      page: CreatePasswordRoute.page,
    ),
    AutoRoute(
      path: '/enter-password',
      page: EnterPasswordRoute.page,
    ),
    AutoRoute(
      path: '/sign-in',
      page: SignInRoute.page,
    ),
    AutoRoute(
      path: '/confirm-password',
      page: ConfirmPasswordRoute.page,
    ),
    AutoRoute(
      path: '/transaction-pin',
      page: CreateTransactionPinRoute.page,
    ),
    AutoRoute(
      path: '/confirm-transaction-pin',
      page: ConfirmTransactionPinRoute.page,
    ),
    AutoRoute(
      path: '/biometric-authentication',
      page: BiometricAuthenticationRoute.page,
    ),
    AutoRoute(
      path: '/qr-code',
      page: QrCodeRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/transfer',
      page: TransferRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/make-payment',
      page: MakePaymentRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/enter-transaction-pin',
      page: EnterPinRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/confirm-payment',
      page: ConfirmPaymentRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/receipt',
      page: ReceiptRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/change-theme',
      page: ChangeThemeRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/forgot-password',
      page: ForgotPasswordRoute.page,
    ),
    AutoRoute(
      path: '/change-password',
      page: ChangePasswordRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/change-pin',
      page: ChangePinRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/notifications',
      page: NotificationsRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/profile',
      page: ProfileRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/referral',
      page: ReferralRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/support',
      page: SupportRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/legal',
      page: LegalRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/add-money',
      page: DepositMoneyRoute.page,
      guards: [AuthenticationGuard(ref)],
    ),
    AutoRoute(
      path: '/home',
      guards: [
        AuthenticationGuard(ref),
        DriverAccountGuard(ref),
      ],
      page: HomeRoute.page,
      children: [
        AutoRoute(
          path: 'dashboard',
          initial: true,
          page: DashboardRoute.page,
        ),
        AutoRoute(
          path: 'transaction-history',
          page: TransactionHistoryRoute.page,
        ),
        AutoRoute(
          path: 'settings',
          page: SettingsRoute.page,
        ),
      ],
    ),
  ];
}

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
