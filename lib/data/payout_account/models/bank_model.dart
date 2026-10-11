import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_model.freezed.dart';
part 'bank_model.g.dart';

@freezed
sealed class BankModel with _$BankModel {
  const factory BankModel({
    required String name,
    required String code,
    @JsonKey(name: 'active') required bool isActive,
  }) = _BankModel;

  factory BankModel.fromJson(Map<String, dynamic> json) =>
      _$BankModelFromJson(json);
}

@freezed
sealed class VerifiedBankAccountModel with _$VerifiedBankAccountModel {
  const factory VerifiedBankAccountModel({
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'account_name') required String accountName,
    @JsonKey(name: 'bank_id') required int bankId,
  }) = _VerifiedBankAccountModel;

  factory VerifiedBankAccountModel.fromJson(Map<String, dynamic> json) =>
      _$VerifiedBankAccountModelFromJson(json);
}
