import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/core/api/exceptions/client_exception.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/api/retry_policy.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/profile/i_profile_repository.dart';
import 'package:paypadi/data/profile/models/user_profile_model.dart';
import 'package:paypadi/data/profile/providers.dart';
import 'package:paypadi/data/transaction/i_transaction_repository.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/data/transaction/providers.dart';
import 'package:paypadi/data/wallet/i_wallet_repository.dart';
import 'package:paypadi/data/wallet/models/user_bank_account_model.dart';
import 'package:paypadi/data/wallet/providers.dart';
import 'package:paypadi/features/home/controllers/bank_account_controller.dart';
import 'package:paypadi/features/transfer/controllers/receipt_controller.dart';
import 'package:paypadi/shared/controllers/user_profile_controller.dart';

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
              createdAt: DateTime.utc(2026, 10, 1, 22, 33, 53),
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

class _ProfileRepository implements IProfileRepository {
  int calls = 0;

  @override
  FutureResultOf<ApiResponse<UserProfileModel>> getUser() async {
    calls++;
    return success(
      ok(
        const UserProfileModel(
          id: 'u1',
          role: AccountType.rider,
          phoneNumber: '+2348031234567',
          firstName: 'Ada',
          lastName: 'Obi',
          isActive: true,
          phoneVerified: true,
          dateJoined: '2026-10-01T09:00:00Z',
          totalReferrals: 0,
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test(
    'the user profile can be reloaded, as the QR screen Retry does',
    () async {
      final profile = _ProfileRepository();
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(profile)],
      );
      addTearDown(container.dispose);
      container.listen(userProfileProvider, (_, _) {});

      await container.read(userProfileProvider.future);
      container.invalidate(userProfileProvider);

      expect(
        (await container.read(userProfileProvider.future))?.firstName,
        'Ada',
      );
      expect(profile.calls, 2);
    },
  );

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
        retryTransientFailures(0, const ServerException.transformTimeout()),
        const Duration(milliseconds: 200),
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
