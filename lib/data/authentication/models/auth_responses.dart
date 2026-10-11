import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paypadi/data/authentication/models/user_model.dart';

part 'auth_responses.freezed.dart';
part 'auth_responses.g.dart';

@freezed
sealed class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({
    @JsonKey(name: 'access') required String accessToken,
    @JsonKey(name: 'refresh') required String refreshToken,
    required UserModel user,
  }) = _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, Object?> json) =>
      _$RegisterResponseFromJson(json);
}

@freezed
sealed class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    @JsonKey(name: 'access') required String accessToken,
    @JsonKey(name: 'refresh') required String refreshToken,
    @JsonKey(name: 'access_expires') required int accessTokenExpiry,
    @JsonKey(name: 'refresh_expires') required int refreshTokenExpiry,
    required UserModel user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, Object?> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
sealed class RequestOtpResponse with _$RequestOtpResponse {
  const factory RequestOtpResponse({
    @JsonKey(name: 'expires_in') required int expiresIn,
    // Not in the API schema; the code is meant to reach the user by SMS.
    String? otp,
  }) = _RequestOtpResponse;

  factory RequestOtpResponse.fromJson(Map<String, Object?> json) =>
      _$RequestOtpResponseFromJson(json);
}

@freezed
sealed class VerifyOtpResponse with _$VerifyOtpResponse {
  const factory VerifyOtpResponse({
    @JsonKey(name: 'phone_token') required String token,
  }) = _VerifyOtpResponse;

  factory VerifyOtpResponse.fromJson(Map<String, Object?> json) =>
      _$VerifyOtpResponseFromJson(json);
}
