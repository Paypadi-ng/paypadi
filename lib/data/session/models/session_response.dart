import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_response.freezed.dart';
part 'session_response.g.dart';

/// Token refresh returns a new access token, plus a new refresh token only
/// when the backend rotates them. It does not return `access_expires` or
/// `refresh_expires`; read the expiry from the tokens' `exp` claim instead.
@freezed
sealed class SessionResponse with _$SessionResponse {
  const factory SessionResponse({
    @JsonKey(name: 'access') required String accessToken,
    @JsonKey(name: 'refresh') String? refreshToken,
    @JsonKey(name: 'access_expires') int? accessTokenExpiry,
    @JsonKey(name: 'refresh_expires') int? refreshTokenExpiry,
  }) = _SessionResponse;

  factory SessionResponse.fromJson(Map<String, Object?> json) =>
      _$SessionResponseFromJson(json);
}
