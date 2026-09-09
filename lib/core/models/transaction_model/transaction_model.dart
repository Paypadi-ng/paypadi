import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paypadi/core/utils/enums.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
sealed class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required int amount,
    required String reference,
    required String recipient,
    @JsonKey(name: 'recipient_name') required String recipientAccount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'payment_type') required String paymentType,
    @JsonKey(
      name: 'transaction_type',
      unknownEnumValue: TransactionType.unknown,
    )
    required TransactionType type,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}

@freezed
sealed class TransactionHistoryModel with _$TransactionHistoryModel {
  const factory TransactionHistoryModel({
    required String id,
    required String amount,
    required String reference,
    required String description,
    required TransactionHistoryMetadata metadata,
    @JsonKey(unknownEnumValue: TransactionStatus.failure)
    required TransactionStatus status,
    @JsonKey(
      name: 'transaction_type',
      unknownEnumValue: TransactionType.unknown,
    )
    required TransactionType type,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'sender_name') required String senderName,
    @JsonKey(name: 'recipient_name') required String recipientName,
    @JsonKey(name: 'fee_amount') required String transactionFee,
  }) = _TransactionHistoryModel;

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionHistoryModelFromJson(json);
}

@freezed
sealed class TransactionHistoryMetadata with _$TransactionHistoryMetadata {
  const factory TransactionHistoryMetadata({
    @JsonKey(name: 'recipient_account') String? receipientAccount,
    @JsonKey(name: 'recipient_bank_code') String? receipientBankCode,
    @JsonKey(name: 'gateway_reference') String? gatewayReference,
    @JsonKey(name: 'pin_verified') bool? isPinVerified,
    @JsonKey(name: 'recipient_phone') String? recipientPhone,
    @JsonKey(name: 'initiated_by') String? initiatedBy,
  }) = _TransactionHistoryMetadata;

  factory TransactionHistoryMetadata.fromJson(Map<String, dynamic> json) =>
      _$TransactionHistoryMetadataFromJson(json);
}
