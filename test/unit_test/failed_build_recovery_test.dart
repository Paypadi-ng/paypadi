import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/api/retry_policy.dart';
import 'package:paypadi/core/models/transaction_model/transaction_model.dart';
import 'package:paypadi/core/models/user_bank_account_model/user_bank_account_model.dart';
import 'package:paypadi/core/repositories/transaction/i_transaction_repository.dart';
import 'package:paypadi/core/repositories/wallet/i_wallet_repository.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/src/features/home/controller/bank_account_controller.dart';
import 'package:paypadi/src/features/transfer/controller/receipt_controller.dart';

import '../helpers/transfer_fakes.dart';

const _noVirtualAccount = ServerException.badRequest(
  'Could not generate virtual account. Please use standard deposit.',
);

const _account = UserBankAccountModel(
  number: '0123456789',
  name: 'Ada Obi',
  bankName: 'Wema Bank',
  bankCode: '035',
);

/// Fails the first deposit-account request, then succeeds.
class _FlakyWalletRepository implements IWalletRepository {
  int calls = 0;

  @override
  FutureApiResultOf<UserBankAccountModel> getDepositAccount() async =>
      calls++ == 0 ? failure(_noVirtualAccount) : success(ok(_account));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FlakyTransactionRepository implements ITransactionRepository {
  int calls = 0;

  @override
  FutureApiResultOf<TransactionHistoryModel> getTransactionDetailsById(
    String reference,
  ) async => calls++ == 0
      ? failure(const ServerException.notFound('Transaction not found'))
      : success(
          ok(
            TransactionHistoryModel(
              id: 't1',
              amount: '200.00',
              reference: reference,
              status: TransactionStatus.completed,
              type: TransactionType.transfer,
              createdAt: '2026-10-01T22:33:53Z',
              senderName: 'Steve Jorkwitz',
              recipientName: 'Olaoluwa Toki',
              transactionFee: '5.00',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('a controller whose build failed', () {
    test('shows the API error straight away and rebuilds cleanly', () async {
      final wallet = _FlakyWalletRepository();
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(wallet)],
      );
      addTearDown(container.dispose);
      container.listen(bankAccountControllerProvider, (_, _) {});

      await expectLater(
        container.read(bankAccountControllerProvider.future),
        throwsA(_noVirtualAccount),
      );
      // Not retried: the 400 is what the screen shows, not a loading state.
      expect(container.read(bankAccountControllerProvider).isLoading, isFalse);
      expect(wallet.calls, 1);

      // Rebuilding used to throw LateInitializationError, replacing the real
      // error and never loading the account.
      container.invalidate(bankAccountControllerProvider);
      expect(
        await container.read(bankAccountControllerProvider.future),
        _account,
      );
    });

    test('works the same for a receipt', () async {
      final transactions = _FlakyTransactionRepository();
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(transactions),
        ],
      );
      addTearDown(container.dispose);
      final receipt = receiptControllerProvider('TRF-1');
      container.listen(receipt, (_, _) {});

      await expectLater(
        container.read(receipt.future),
        throwsA(isA<ServerException>()),
      );

      container.invalidate(receipt);
      expect((await container.read(receipt.future))?.reference, 'TRF-1');
    });
  });

  group('retryTransientFailures', () {
    test('retries failures that can clear up, with growing delays', () {
      expect(
        retryTransientFailures(0, const ServerException.requestTimeout()),
        const Duration(milliseconds: 200),
      );
      expect(
        retryTransientFailures(3, const ServerException.noInternetConnection()),
        const Duration(milliseconds: 1600),
      );
      expect(
        retryTransientFailures(8, const ServerException.serviceUnavailable()),
        const Duration(milliseconds: 6400),
      );
      expect(
        retryTransientFailures(10, const ServerException.requestTimeout()),
        isNull,
      );
    });

    test('does not retry client errors or bad responses', () {
      expect(retryTransientFailures(0, _noVirtualAccount), isNull);
      expect(
        retryTransientFailures(0, const ServerException.notFound(null)),
        isNull,
      );
      expect(
        retryTransientFailures(0, const ClientException(message: 'bad json')),
        isNull,
      );
    });
  });
}
