import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/src/features/transfer/controller/transfer_draft.dart';
import 'package:paypadi/src/features/transfer/views/confirm_payment.dart';
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';

import '../helpers/transfer_fakes.dart';

void main() {
  testWidgets('Make Payment is disabled while the transfer is in flight, so '
      'a second tap sends nothing', (tester) async {
    final repository = FakeTransactionRepository();
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repository),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    container.read(transferDraftControllerProvider.notifier)
      ..start(amount: '1500')
      ..setRecipient(accountNumber: '0123456789')
      ..setPin('1234');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: appDesignSize,
          builder: (_, _) => const MaterialApp(home: ConfirmPaymentScreen()),
        ),
      ),
    );

    final makePayment = find.widgetWithText(FilledButton, 'Make Payment');
    expect(tester.widget<FilledButton>(makePayment).onPressed, isNotNull);

    await tester.tap(makePayment);
    await tester.pump();

    expect(tester.widget<FilledButton>(makePayment).onPressed, isNull);
    await tester.tap(makePayment, warnIfMissed: false);
    await tester.pump();
    expect(repository.transfers, hasLength(1));

    repository.completeTransfer();
    await tester.pumpAndSettle();
  });

  testWidgets('shows no fee row, since the payment summary has no fee', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          FakeTransactionRepository(),
        ),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: appDesignSize,
          builder: (_, _) => const MaterialApp(home: ConfirmPaymentScreen()),
        ),
      ),
    );

    expect(find.text('Transaction Fee'), findsNothing);
    expect(find.text('Confirm Payment'), findsOneWidget);
  });
}
