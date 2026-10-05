import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/models/account_payout_model/account_payout_model.dart';
import 'package:paypadi/core/models/bank_model/bank_model.dart';
import 'package:paypadi/core/repositories/payout_account/i_payout_account_repository.dart';
import 'package:paypadi/core/repositories/wallet/i_wallet_repository.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bank_account_controller.g.dart';

@riverpod
class BankListController extends _$BankListController {
  @override
  FutureOr<List<BankModel>> build() async {
    final repository = ref.watch(payoutAccountRepositoryProvider);
    final result = await repository.getListOfBanks();

    return result.fold(
      (success) => success,
      (failure) {
        ref.showExceptionMessage(failure);
        return <BankModel>[];
      },
    );
  }

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }
}

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
