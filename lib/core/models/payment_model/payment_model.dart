import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paypadi/core/utils/enums.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

@freezed
sealed class PaymentModel with _$PaymentModel {
  const factory PaymentModel({
    required String amount,
    @JsonKey(name: 'transaction_reference') required String reference,
    @JsonKey(name: 'authorization_url') required String authorizationUrl,
    @JsonKey(name: 'transaction_id') required String transactionId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(
      name: 'payment_type',
      unknownEnumValue: TransactionType.unknown,
    )
    required TransactionType paymentType,
  }) = _PaymentModel;

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);
}
