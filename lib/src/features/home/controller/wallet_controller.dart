import 'package:flutter/foundation.dart' show immutable;
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

/// The transactions loaded so far, newest first.
@immutable
class TransactionHistory {
  const TransactionHistory({
    required this.items,
    required this.nextPage,
    this.isLoadingMore = false,
  });

  final List<TransactionHistoryModel> items;

  /// The page to load next, or null once every page has been loaded.
  final int? nextPage;

  final bool isLoadingMore;

  bool get hasMore => nextPage != null;
}

@riverpod
class HistoryController extends _$HistoryController {
  @override
  FutureOr<TransactionHistory> build() async {
    final repository = ref.watch(walletRepositoryProvider);
    final result = await repository.getTransactionHistory();

    if (!ref.mounted) {
      return const TransactionHistory(items: [], nextPage: null);
    }

    return result.fold(
      (success) => TransactionHistory(
        items: success.data.results,
        nextPage: success.data.next != null ? 2 : null,
      ),
      (failure) {
        ref.showExceptionMessage(failure);
        return const TransactionHistory(items: [], nextPage: null);
      },
    );
  }

  /// Appends the next page. A failure keeps what's already loaded.
  Future<void> loadMore() async {
    final current = state.value;
    final page = current?.nextPage;
    if (current == null || page == null || current.isLoadingMore) return;

    state = AsyncData(
      TransactionHistory(
        items: current.items,
        nextPage: page,
        isLoadingMore: true,
      ),
    );

    final result = await ref
        .read(walletRepositoryProvider)
        .getTransactionHistory(page: page);

    if (!ref.mounted) return;

    result.fold(
      (success) => state = AsyncData(
        TransactionHistory(
          items: [...current.items, ...success.data.results],
          nextPage: success.data.next != null ? page + 1 : null,
        ),
      ),
      (failure) {
        ref.showExceptionMessage(failure);
        state = AsyncData(current);
      },
    );
  }
}
