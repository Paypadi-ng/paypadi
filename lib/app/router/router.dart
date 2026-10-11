import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/router/guards.dart';
import 'package:paypadi/app/router/router.gr.dart';

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
      path: '/authenticate-transfer',
      page: AuthenticateTransferRoute.page,
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
