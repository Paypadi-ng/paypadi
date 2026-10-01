import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_draft.g.dart';

/// Strips everything but digits and the decimal point, e.g. "₦1,500" → "1500".
String cleanTransferAmount(String input) =>
    input.replaceAll(RegExp(r'[^0-9.]'), '');

/// Form validator for a transfer amount: a number above zero.
String? transferAmountValidator(String? input) {
  final amount = num.tryParse(cleanTransferAmount(input ?? ''));
  if (amount == null) return 'Enter an amount';
  if (amount <= 0) return 'Enter an amount above zero';
  return null;
}

/// Which field `/wallets/payments/lookup/` should search a recipient by.
enum LookupBy {
  phoneNumber('phone_number'),
  accountNumber('account_number');

  const LookupBy(this.field);

  /// The request field the backend expects.
  final String field;

  /// Guesses what the user typed: an 11-digit number starting with 0, or a
  /// number with the +234/234 country code, is a phone number; anything
  /// else is treated as a 10-digit account number, as the input hint asks.
  static LookupBy infer(String input) {
    final digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
    final isLocalPhone = RegExp(r'^0\d{10}$').hasMatch(digits);
    final isInternationalPhone = RegExp(r'^\+?234\d{10}$').hasMatch(digits);
    return isLocalPhone || isInternationalPhone ? phoneNumber : accountNumber;
  }
}

/// What the user has entered for the transfer in progress.
@immutable
class TransferDraft {
  const TransferDraft({
    this.amount,
    this.description,
    this.recipientAccountNumber,
    this.recipientBankCode,
    this.pin,
  });

  final String? amount;
  final String? description;
  final String? recipientAccountNumber;
  final String? recipientBankCode;
  final String? pin;

  bool get hasAmount => amount?.isNotEmpty ?? false;

  /// The body for `/wallets/payments/initiate/`.
  Map<String, dynamic> toInitiatePayload() => {
    'amount': amount,
    'transaction_type': 'transfer',
    if (description case final text? when text.isNotEmpty) 'description': text,
  };

  /// The body for `/wallets/transfer/`.
  Map<String, dynamic> toTransferPayload() => {
    'amount': amount,
    'pin': pin,
    if (description case final text? when text.isNotEmpty) 'description': text,
    'recipient_account_number': recipientAccountNumber,
    if (recipientBankCode != null) 'recipient_bank_code': recipientBankCode,
  };
}

/// The transfer being filled in across the transfer screens.
///
/// Every way into the flow calls [start], so nothing from a previous
/// transfer (amount, recipient or PIN) carries over into the next one.
@Riverpod(keepAlive: true)
class TransferDraftController extends _$TransferDraftController {
  @override
  TransferDraft build() => const TransferDraft();

  /// Starts a new transfer, discarding anything left from the last one.
  void start({String? amount}) => state = TransferDraft(amount: amount);

  void setAmount(String amount) => state = TransferDraft(
    amount: amount,
    description: state.description,
    recipientAccountNumber: state.recipientAccountNumber,
    recipientBankCode: state.recipientBankCode,
    pin: state.pin,
  );

  void setRecipient({
    required String accountNumber,
    String? bankCode,
    String? description,
  }) => state = TransferDraft(
    amount: state.amount,
    description: description,
    recipientAccountNumber: accountNumber,
    recipientBankCode: bankCode,
    pin: state.pin,
  );

  void setPin(String pin) => state = TransferDraft(
    amount: state.amount,
    description: state.description,
    recipientAccountNumber: state.recipientAccountNumber,
    recipientBankCode: state.recipientBankCode,
    pin: pin,
  );

  /// Forgets the transfer, including the PIN.
  void clear() => state = const TransferDraft();
}
