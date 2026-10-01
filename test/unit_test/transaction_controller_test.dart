import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/src/features/transfer/controller/transaction_controller.dart';
import 'package:paypadi/src/features/transfer/controller/transfer_draft.dart';
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';

import '../helpers/transfer_fakes.dart';

void main() {
  late FakeTransactionRepository repository;
  late RecordingRouter router;
  late ProviderContainer container;

  setUp(() {
    repository = FakeTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repository),
        appRouterProvider.overrideWith((ref) => RecordingRouter(ref: ref)),
        appToastControllerProvider.overrideWith(SilentToastController.new),
      ],
    );
    addTearDown(container.dispose);
    router = container.read(appRouterProvider) as RecordingRouter;
    // Keep the auto-dispose controllers alive, as their screens do.
    container
      ..listen(transactionControllerProvider, (_, _) {})
      ..listen(initiatePaymentControllerProvider, (_, _) {});

    container.read(transferDraftControllerProvider.notifier)
      ..start(amount: '1500')
      ..setRecipient(accountNumber: '0123456789', bankCode: '058')
      ..setPin('1234');
  });

  TransferDraft draft() => container.read(transferDraftControllerProvider);

  group('TransactionController.transfer', () {
    test('sends the money once when tapped again before it returns', () async {
      final controller = container.read(transactionControllerProvider.notifier);

      final first = controller.transfer();
      final second = controller.transfer();
      repository.completeTransfer();
      await Future.wait([first, second]);

      expect(repository.transfers, hasLength(1));
      expect(repository.transfers.single['pin'], '1234');
    });

    test('forgets the draft, PIN included, and shows the receipt once the '
        'money has moved', () async {
      final transfer = container
          .read(transactionControllerProvider.notifier)
          .transfer();
      repository.completeTransfer();
      await transfer;

      expect(draft().pin, isNull);
      expect(draft().hasAmount, isFalse);
      expect(
        router.pushed.single,
        isA<ReceiptRoute>().having(
          (route) => route.args?.referenceId,
          'referenceId',
          'PPD-123',
        ),
      );
    });

    test('keeps the draft after a failure so the user can retry', () async {
      final transfer = container
          .read(transactionControllerProvider.notifier)
          .transfer();
      repository.failTransfer();
      await transfer;

      expect(draft().amount, '1500');
      expect(draft().pin, '1234');
      expect(router.pushed, isEmpty);
    });
  });

  group('InitiatePaymentController.initiatePayment', () {
    test(
      'sends the draft amount once, even when the PIN is submitted again',
      () async {
        final controller = container.read(
          initiatePaymentControllerProvider.notifier,
        );

        final first = controller.initiatePayment();
        final second = controller.initiatePayment();
        repository.completeInitiate();
        await Future.wait([first, second]);

        expect(repository.initiations, [
          {'amount': '1500', 'transaction_type': 'transfer'},
        ]);
        expect(router.pushed.single, isA<ConfirmPaymentRoute>());
      },
    );
  });

  group('AccountLookup', () {
    test('looks a beneficiary up by account number', () async {
      await container.read(
        accountLookupProvider('0123456789', LookupBy.accountNumber).future,
      );

      expect(repository.lookups.single, {'account_number': '0123456789'});
    });

    test('looks a scanned QR code up by phone number', () async {
      await container.read(
        accountLookupProvider('08031234567', LookupBy.phoneNumber).future,
      );

      expect(repository.lookups.single, {'phone_number': '08031234567'});
    });
  });
}
