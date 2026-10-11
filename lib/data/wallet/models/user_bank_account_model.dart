import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_bank_account_model.freezed.dart';
part 'user_bank_account_model.g.dart';

@freezed
sealed class UserBankAccountModel with _$UserBankAccountModel {
  const factory UserBankAccountModel({
    @JsonKey(name: 'account_number') required String number,
    @JsonKey(name: 'account_name') required String name,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'bank_code') required String bankCode,
    bool? assigned,
    bool? verified,
    String? currency,
  }) = _UserBankAccountModel;

  factory UserBankAccountModel.fromJson(Map<String, dynamic> json) =>
      _$UserBankAccountModelFromJson(json);
}
