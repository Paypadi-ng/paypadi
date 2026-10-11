import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_lookup_model.freezed.dart';
part 'account_lookup_model.g.dart';

@freezed
sealed class AccountLookupModel with _$AccountLookupModel {
  const factory AccountLookupModel({
    required String role,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'bank_code') String? bankCode,
    @JsonKey(name: 'profile_picture') String? profilePicUrl,
  }) = _AccountLookupModel;

  factory AccountLookupModel.fromJson(Map<String, dynamic> json) =>
      _$AccountLookupModelFromJson(json);
}
