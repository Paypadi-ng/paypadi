import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/utils/helpers.dart';

String _token(Map<String, dynamic> claims) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(json.encode(part))).replaceAll('=', '');

  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(claims)}.signature';
}

void main() {
  group('jwtExpiry', () {
    test('reads the exp claim', () {
      expect(
        jwtExpiry(_token({'exp': 1767225600, 'user_id': 'abc'})),
        1767225600,
      );
    });

    test('returns null when there is no exp claim', () {
      expect(jwtExpiry(_token({'user_id': 'abc'})), isNull);
    });

    test('returns null for a token that is not a JWT', () {
      expect(jwtExpiry('not-a-jwt'), isNull);
      expect(jwtExpiry('a.%%%.c'), isNull);
    });
  });
}
