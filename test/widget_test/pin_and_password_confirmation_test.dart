import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/repositories/profile/i_profile_repository.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';
import 'package:paypadi/src/shared/views/password/confirm_password_screen.dart';
import 'package:paypadi/src/shared/views/transaction_pin/confirm_transaction_pin_screen.dart';

import '../helpers/transfer_fakes.dart';

class _FakeProfileRepository implements IProfileRepository {
  final List<Map<String, dynamic>> pins = [];

  @override
  Future<Result<ApiResponse<void>, Exception>> setTransactionPin(
    Map<String, dynamic> payload,
  ) async {
    pins.add(payload);
    return success(ok<void>(null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late SilentToastController toasts;
  late _FakeProfileRepository profile;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    // A phone-sized screen; the default 800x600 test surface is too short.
    tester.view
      ..physicalSize = appDesignSize * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        appToastControllerProvider.overrideWith(SilentToastController.new),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        profileRepositoryProvider.overrideWithValue(
          profile = _FakeProfileRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    toasts =
        container.read(appToastControllerProvider.notifier)
            as SilentToastController;

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

  Future<void> typeOnKeypad(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.text(digit).last);
      await tester.pump();
    }
  }

  testWidgets('a mismatched PIN says so and clears the keypad for another '
      'try', (tester) async {
    await pump(tester, const ConfirmTransactionPinScreen(pin: '1234'));

    await typeOnKeypad(tester, '1235');

    expect(toasts.errors, [pinMismatchMessage]);
    expect(profile.pins, isEmpty);

    // The keypad was cleared, so the right PIN can be entered and sent.
    await typeOnKeypad(tester, '1234');
    await tester.pumpAndSettle();

    expect(profile.pins.single['new_pin'], '1234');
  });

  testWidgets('a mismatched password says so', (
    tester,
  ) async {
    await pump(tester, const ConfirmPasswordScreen(password: '123456'));

    await typeOnKeypad(tester, '123457');
    await tester.pumpAndSettle();

    expect(toasts.errors, [passwordMismatchMessage]);
  });
}
