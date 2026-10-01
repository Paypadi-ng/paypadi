import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/src/features/transfer/controller/transfer_draft.dart';

void main() {
  group('LookupBy.infer', () {
    test('treats Nigerian phone numbers as phone numbers', () {
      for (final input in [
        '08031234567',
        '0803 123 4567',
        '+2348031234567',
        '2348031234567',
      ]) {
        expect(LookupBy.infer(input), LookupBy.phoneNumber, reason: input);
      }
    });

    test('treats a 10-digit number as an account number', () {
      expect(LookupBy.infer('0123456789'), LookupBy.accountNumber);
      expect(LookupBy.infer('8031234567'), LookupBy.accountNumber);
    });

    test('sends the field the backend expects', () {
      expect(LookupBy.phoneNumber.field, 'phone_number');
      expect(LookupBy.accountNumber.field, 'account_number');
    });
  });

  group('transfer amount', () {
    test('cleans currency formatting', () {
      expect(cleanTransferAmount('₦1,500.50'), '1500.50');
    });

    test('accepts positive amounts only', () {
      expect(transferAmountValidator('1500'), isNull);
      expect(transferAmountValidator(''), 'Enter an amount');
      expect(transferAmountValidator('abc'), 'Enter an amount');
      expect(transferAmountValidator('0'), 'Enter an amount above zero');
    });
  });

  group('TransferDraftController', () {
    late ProviderContainer container;
    TransferDraftController draft() =>
        container.read(transferDraftControllerProvider.notifier);
    TransferDraft state() => container.read(transferDraftControllerProvider);

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('starting a new transfer drops everything from the last one', () {
      draft()
        ..start(amount: '5000')
        ..setRecipient(
          accountNumber: '0123456789',
          bankCode: '058',
          description: 'Rent',
        )
        ..setPin('1234')
        ..start();

      expect(state().amount, isNull);
      expect(state().recipientAccountNumber, isNull);
      expect(state().description, isNull);
      expect(state().pin, isNull);
    });

    test('builds the transfer body from what was entered', () {
      draft()
        ..start(amount: '1500')
        ..setRecipient(
          accountNumber: '0123456789',
          bankCode: '058',
          description: 'Lunch',
        )
        ..setPin('1234');

      expect(state().toTransferPayload(), {
        'amount': '1500',
        'pin': '1234',
        'description': 'Lunch',
        'recipient_account_number': '0123456789',
        'recipient_bank_code': '058',
      });
      expect(state().toInitiatePayload(), {
        'amount': '1500',
        'transaction_type': 'transfer',
        'description': 'Lunch',
      });
    });

    test('leaves out an empty description and a missing bank code', () {
      draft()
        ..start(amount: '1500')
        ..setRecipient(accountNumber: '0123456789', description: '')
        ..setPin('1234');

      expect(
        state().toTransferPayload().keys,
        unorderedEquals(['amount', 'pin', 'recipient_account_number']),
      );
    });

    test('clear forgets the PIN', () {
      draft()
        ..start(amount: '1500')
        ..setPin('1234')
        ..clear();

      expect(state().pin, isNull);
      expect(state().hasAmount, isFalse);
    });
  });
}
