import 'dart:async';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/models/account_lookup_model/account_lookup_model.dart';
import 'package:paypadi/core/models/payment_model/payment_model.dart';
import 'package:paypadi/core/models/transaction_model/transaction_model.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/src/features/transfer/controller/transfer_draft.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_controller.g.dart';

@riverpod
class AccountLookup extends _$AccountLookup {
  @override
  FutureOr<AccountLookupModel?> build(
    String recipient,
    LookupBy lookupBy,
  ) async {
    final repository = ref.watch(transactionRepositoryProvider);
    final result = await repository.getAccountDetails({
      lookupBy.field: recipient,
    });

    return result.fold(
      (success) => success.data,
      (failure) {
        ref.showExceptionMessage(failure);
        return null;
      },
    );
  }
}

@riverpod
class InitiatePaymentController extends _$InitiatePaymentController {
  @override
  FutureOr<PaymentModel?> build() => null;

  Future<void> initiatePayment() async {
    // The keypad submits on every completed PIN; ignore repeats while a
    // request is already in flight.
    if (state.isLoading) return;

    final draft = ref.read(transferDraftControllerProvider);
    state = const AsyncLoading();

    final result = await ref
        .read(transactionRepositoryProvider)
        .initiatePayment(draft.toInitiatePayload());

    if (!ref.mounted) return;

    result.fold(
      (success) {
        state = AsyncValue.data(success.data);
        unawaited(
          ref.read(appRouterProvider).push(const ConfirmPaymentRoute()),
        );
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }
}

@riverpod
class TransactionController extends _$TransactionController {
  @override
  FutureOr<TransactionModel?> build() => null;

  Future<void> transfer() async {
    // A second tap before the first transfer returns must not send the
    // money again.
    if (state.isLoading) return;

    final payload = ref
        .read(transferDraftControllerProvider)
        .toTransferPayload();
    state = const AsyncLoading();

    final result = await ref
        .read(transactionRepositoryProvider)
        .transfer(payload);

    if (!ref.mounted) return;

    result.fold(
      (success) {
        // The money has moved: forget the draft, PIN included, so nothing
        // can be resent or reused by the next transfer.
        ref.read(transferDraftControllerProvider.notifier).clear();
        state = AsyncValue.data(success.data);
        unawaited(
          ref
              .read(appRouterProvider)
              .push(ReceiptRoute(referenceId: success.data.reference)),
        );
      },
      (failure) {
        // Keep the draft so the user can retry from the confirm screen.
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }
}
