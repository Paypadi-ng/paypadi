import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/data/payout_account/i_payout_account_repository.dart';
import 'package:paypadi/data/payout_account/models/account_payout_model.dart';
import 'package:paypadi/data/payout_account/models/bank_model.dart';
import 'package:paypadi/data/payout_account/providers.dart';
import 'package:paypadi/data/wallet/i_wallet_repository.dart';
import 'package:paypadi/data/wallet/providers.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payout_account_controller.g.dart';

@riverpod
class VerifiedBankAccount extends _$VerifiedBankAccount {
  late IWalletRepository _repository;

  @override
  FutureOr<VerifiedBankAccountModel?> build() {
    _repository = ref.watch(walletRepositoryProvider);
    return null;
  }

  Future<void> verifyBankInformation(Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    final result = await _repository.verifyBankInformation(payload);

    // Check if provider is still mounted
    if (!ref.mounted) return;

    await result.fold(
      (success) async => state = AsyncData(success),
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }
}

@riverpod
class PayoutAccount extends _$PayoutAccount {
  late IPayoutAccountRepository _repository;

  @override
  FutureOr<AccountPayoutModel?> build() {
    _repository = ref.watch(payoutAccountRepositoryProvider);
    return null;
  }

  Future<void> createPayoutAccount(Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    final result = await _repository.createAccount(payload);

    // Check if provider is still mounted
    if (!ref.mounted) return;

    await result.fold(
      (success) async {
        state = AsyncData(success.data);
        await ref.read(appRouterProvider).push(const SignInRoute());
      },
      (failure) {
        state = const AsyncData(null);
        ref.showExceptionMessage(failure);
      },
    );
  }
}
