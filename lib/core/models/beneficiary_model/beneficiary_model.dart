import 'package:freezed_annotation/freezed_annotation.dart';

part 'beneficiary_model.freezed.dart';
part 'beneficiary_model.g.dart';

@freezed
sealed class BeneficiaryModel with _$BeneficiaryModel {
  const factory BeneficiaryModel({
    @JsonKey(name: 'beneficiary_type') required String type,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'account_name') required String accountName,
    String? id,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'bank_code') String? bankCode,
    @JsonKey(name: 'is_saved') bool? isSaved,
    @JsonKey(name: 'is_verified') bool? isVerified,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'last_transaction_at') DateTime? lastTransaction,
  }) = _BeneficiaryModel;

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) =>
      _$BeneficiaryModelFromJson(json);
}
