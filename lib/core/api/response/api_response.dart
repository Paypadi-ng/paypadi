import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paypadi/core/models/user_model/user_model.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@Freezed(genericArgumentFactories: true)
sealed class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool status,
    required String message,
    required T data,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}

@Freezed(genericArgumentFactories: true)
sealed class ApiListResponse<T> with _$ApiListResponse<T> {
  const factory ApiListResponse({
    required bool status,
    required String message,
    required List<T> data,
  }) = _ApiListResponse;

  factory ApiListResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiListResponseFromJson(json, fromJsonT);
}

@Freezed(genericArgumentFactories: true)
sealed class PaginatedListResponse<T> with _$PaginatedListResponse<T> {
  const factory PaginatedListResponse({
    required int count,
    required List<T> results,
    String? next,
    String? previous,
  }) = _PaginatedListResponse;

  factory PaginatedListResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedListResponseFromJson(json, fromJsonT);
}

@freezed
sealed class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({
    @JsonKey(name: 'access') required String accessToken,
    @JsonKey(name: 'refresh') required String refreshToken,
    @JsonKey(name: 'access_expires') required int accessTokenExpiry,
    @JsonKey(name: 'refresh_expires') required int refreshTokenExpiry,
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
sealed class SessionResponse with _$SessionResponse {
  const factory SessionResponse({
    @JsonKey(name: 'access') required String accessToken,
    @JsonKey(name: 'refresh') required String refreshToken,
    @JsonKey(name: 'access_expires') required int accessTokenExpiry,
    @JsonKey(name: 'refresh_expires') required int refreshTokenExpiry,
  }) = _SessionResponse;

  factory SessionResponse.fromJson(Map<String, Object?> json) =>
      _$SessionResponseFromJson(json);
}

@freezed
sealed class RequestOtpResponse with _$RequestOtpResponse {
  const factory RequestOtpResponse({
    required String otp,
    @JsonKey(name: 'expires_in') required int expiresIn,
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
