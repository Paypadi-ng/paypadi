import 'dart:async';

import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/router/router.gr.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/providers.dart';
import 'package:paypadi/data/transaction/models/account_lookup_model.dart';
import 'package:paypadi/data/transaction/models/payment_model.dart';
import 'package:paypadi/data/transaction/models/transaction_model.dart';
import 'package:paypadi/data/transaction/providers.dart';
import 'package:paypadi/features/transfer/controllers/transfer_draft.dart';
import 'package:paypadi/shared/extensions/ref_feedback.dart';
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

  /// Starts the payment with the PIN in the transfer draft.
  ///
  /// [pinFromVault]: the PIN came from the biometric PIN vault.
  /// If the server refuses it, the stored PIN is forgotten so a stale one
  /// (e.g. changed on another device) isn't offered again.
  ///
  /// [rememberPin]: biometric confirmation is on, so a typed PIN the server
  /// accepts is stored for next time. Only accepted PINs are ever stored.
  Future<void> initiatePayment({
    bool pinFromVault = false,
    bool rememberPin = false,
  }) async {
    // The keypad submits on every completed PIN; ignore repeats while a
    // request is already in flight.
    if (state.isLoading) return;

    final draft = ref.read(transferDraftControllerProvider);
    state = const AsyncLoading();

    final result = await ref
        .read(transactionRepositoryProvider)
        .initiatePayment(draft.toInitiatePayload());

    if (!ref.mounted) return;

    final vault = ref.read(transactionPinVaultProvider);
    result.fold(
      (success) {
        final pin = draft.pin;
        if (rememberPin && !pinFromVault && pin != null) {
          unawaited(vault.save(pin));
        }
        state = AsyncValue.data(success.data);
        unawaited(
          ref.read(appRouterProvider).push(const ConfirmPaymentRoute()),
        );
      },
      (failure) {
        if (pinFromVault &&
            failure is ServerException &&
            failure.isRejectedInput) {
          unawaited(vault.clear());
        }
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
