import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_payout_model.freezed.dart';
part 'account_payout_model.g.dart';

@freezed
sealed class AccountPayoutModel with _$AccountPayoutModel {
  const factory AccountPayoutModel({
    required int id,
    @JsonKey(name: 'account_type') required String accountType,
    @JsonKey(name: 'account_name') required String accountName,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'is_primary') required bool isPrimary,
    @JsonKey(name: 'is_verified') required bool isVerified,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    // Mobile-money accounts have no bank.
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'bank_code') String? bankCode,
  }) = _AccountPayoutModel;

  factory AccountPayoutModel.fromJson(Map<String, dynamic> json) =>
      _$AccountPayoutModelFromJson(json);
}
