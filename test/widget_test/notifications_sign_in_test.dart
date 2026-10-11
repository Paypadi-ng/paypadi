import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/core/services/device/url_launcher_service.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/notifications/notifications_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/authentication/i_authentication_repository.dart';
import 'package:paypadi/data/authentication/models/auth_responses.dart';
import 'package:paypadi/data/authentication/models/user_model.dart';
import 'package:paypadi/data/authentication/providers.dart';
import 'package:paypadi/features/authentication/controllers/authentication_controller.dart';
import 'package:paypadi/features/authentication/views/forgot_password_screen.dart';
import 'package:paypadi/features/authentication/views/sign_in_screen.dart';
import 'package:paypadi/shared/controllers/app_toast_controller.dart';

import '../helpers/transfer_fakes.dart';

/// Notification setup that always fails, and a token stream whose
/// listeners the test can see.
class _BrokenNotifications implements INotificationsService {
  final tokens = StreamController<String>.broadcast();

  Future<void> dispose() => tokens.close();

  @override
  Future<void> initialize() async => throw Exception('APNs not configured');

  @override
  Future<bool> requestPermission() async =>
      throw Exception('Permission request failed');

  @override
  Stream<String> get onTokenRefresh => tokens.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeAuthRepository implements IAuthenticationRepository {
  @override
  FutureResultOf<ApiResponse<LoginResponse>> login(
    Map<String, dynamic> payload,
  ) async => success(
    ok(
      LoginResponse(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessTokenExpiry: 4102444800,
        refreshTokenExpiry: 4102444800,
        user: UserModel(
          id: 'u1',
          role: 'rider',
          phoneNumber: '08031234567',
          firstName: 'Ada',
          lastName: 'Obi',
          isActive: true,
          phoneVerified: true,
          dateJoined: DateTime.utc(2026, 10, 1, 9),
        ),
      ),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _NoopMonitoring implements MonitoringService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Records the links it's asked to open.
class _RecordingLauncher extends UrlLauncherService {
  final List<String?> opened = [];

  @override
  Future<void> launchWebUrl(String? url) async => opened.add(url);
}

void main() {
  late _BrokenNotifications notifications;
  late RecordingRouter router;

  ProviderContainer containerWithBrokenNotifications() {
    FlutterSecureStorage.setMockInitialValues({});
    notifications = _BrokenNotifications();
    addTearDown(notifications.dispose);
    final container = ProviderContainer(
      overrides: [
        monitoringProvider.overrideWithValue(_NoopMonitoring()),
        notificationsServiceProvider.overrideWithValue(notifications),
        authenticationRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(),
        ),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    router = container.read(appRouterProvider) as RecordingRouter;
    return container;
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen,
  ) async {
    tester.view
      ..physicalSize = appDesignSize * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: appDesignSize,
          builder: (_, _) => MaterialApp(home: screen),
        ),
      ),
    );
  }

  testWidgets('a failing notification setup does not stop sign-in', (
    tester,
  ) async {
    final container = containerWithBrokenNotifications();
    addTearDown(container.dispose);
    await pump(tester, container, const SignInScreen());

    await tester.enterText(find.byType(TextFormField), '08031234567');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(router.pushed.single, isA<EnterPasswordRoute>());
  });

  test('a failing notification permission does not stop the login, and the '
      'token listener goes away with the controller', () async {
    final container = containerWithBrokenNotifications();
    final subscription = container.listen(
      authenticationControllerProvider,
      (_, _) {},
    );

    await container
        .read(authenticationControllerProvider.notifier)
        .login('08031234567', '123456');

    expect(router.pushed.single, isA<DashboardRoute>());
    expect(container.read(authenticationControllerProvider).isLoading, false);
    expect(notifications.tokens.hasListener, isTrue);

    subscription.close();
    await pumpEventQueue();
    expect(notifications.tokens.hasListener, isFalse);
    container.dispose();
  });

  testWidgets('Forgot Password no longer claims an email was sent', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await pump(tester, container, const ForgotPasswordScreen());

    expect(find.text(passwordResetUnavailableMessage), findsOneWidget);
    expect(find.textContaining("We've sent"), findsNothing);
  });

  testWidgets('Forgot Password opens the support page', (tester) async {
    final launcher = _RecordingLauncher();
    final container = ProviderContainer(
      overrides: [urlLauncherProvider.overrideWithValue(launcher)],
    );
    addTearDown(container.dispose);
    await pump(tester, container, const ForgotPasswordScreen());

    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();

    expect(launcher.opened, [appSupportAndFaqs]);
  });
}
