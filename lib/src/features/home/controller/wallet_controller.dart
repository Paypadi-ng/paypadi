import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/core/models/account_lookup_model/account_lookup_model.dart';
import 'package:paypadi/core/models/transaction_model/transaction_model.dart';
import 'package:paypadi/core/models/wallet_model/wallet_model.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_controller.g.dart';

@riverpod
class WalletController extends _$WalletController {
  @override
  FutureOr<WalletModel?> build() async {
    final repository = ref.watch(walletRepositoryProvider);

    state = const AsyncLoading();
    final result = await repository.fetchWalletBalance();

    result.fold(
      (success) => state = AsyncValue.data(success.data),
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );

    return state.value;
  }

  Future<void> getWalletInfo() async {
    state = const AsyncLoading();
    final result = await ref
        .read(walletRepositoryProvider)
        .fetchWalletBalance();

    // Check if provider is still mounted
    if (!ref.mounted) return;

    result.fold(
      (success) => state = AsyncValue.data(success.data),
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }

  Future<void> saveBeneficiary(AccountLookupModel beneficiary) async {
    final Map<String, dynamic> payload = {
      'beneficiary_type': 'user',
      'account_number': beneficiary.accountNumber,
      'account_name': '${beneficiary.firstName} ${beneficiary.lastName}',
      'bank_code': beneficiary.bankCode,
    };

    // Saving a beneficiary doesn't change the wallet, so leave the balance
    // alone; it used to be replaced with null here.
    final result = await ref
        .read(walletRepositoryProvider)
        .saveBeneficiary(payload);

    if (!ref.mounted) return;

    result.fold(
      (_) => null,
      ref.showExceptionMessage,
    );
  }
}

@riverpod
class HistoryController extends _$HistoryController {
  @override
  FutureOr<List<TransactionHistoryModel>> build() async {
    final repository = ref.watch(walletRepositoryProvider);
    final result = await repository.getTransactionHistory();

    if (!ref.mounted) return List.empty();

    return result.fold(
      (success) => success.data.results,
      (failure) {
        ref.showExceptionMessage(failure);
        return <TransactionHistoryModel>[];
      },
    );
  }

  Future<void> fetchMore(int page) async {
    state = const AsyncLoading();
    final result = await ref
        .read(walletRepositoryProvider)
        .getTransactionHistory(page: page);

    if (!ref.mounted) return;

    result.fold(
      (success) =>
          state = AsyncData([...?state.value, ...success.data.results]),
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(<TransactionHistoryModel>[]);
      },
    );
  }
}
