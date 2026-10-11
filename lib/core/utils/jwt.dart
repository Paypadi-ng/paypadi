import 'dart:convert';

/// The `exp` claim (seconds since epoch) of a JWT, or null when [token] is
/// not a readable JWT.
int? jwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = json.decode(payload);
    return claims is Map && claims['exp'] is num
        ? (claims['exp'] as num).toInt()
        : null;
  } on FormatException {
    return null;
  }
}
