import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/utils/validators.dart';

void main() {
  group('nameValidator', () {
    test('accepts a single ASCII name', () {
      expect(nameValidator('Michael'), isNull);
      expect(nameValidator('michael'), isNull);
    });

    test('rejects multi-word names', () {
      expect(nameValidator('Michael Jordan'), isNotNull);
    });

    test('rejects empty or null', () {
      expect(nameValidator(''), isNotNull);
      expect(nameValidator(null), isNotNull);
    });

    test('rejects names with non-ASCII letters (diacritics) currently', () {
      // current validator purposely only allows ASCII letters
      expect(nameValidator('José'), isNotNull);
    });

    test('rejects names with numbers or symbols', () {
      expect(nameValidator('M1chael'), isNotNull);
      expect(nameValidator('Michael!'), isNotNull);
    });
  });

  group('otpValidator', () {
    test('accepts 4 and 6 digit OTPs', () {
      expect(otpValidator('1234'), isNull);
      expect(otpValidator('123456'), isNull);
    });

    test('rejects too short or too long OTPs', () {
      expect(otpValidator('123'), isNotNull);
      expect(otpValidator('1234567'), isNotNull);
    });

    test('rejects non-numeric OTPs and empty/null', () {
      expect(otpValidator('12a4'), isNotNull);
      expect(otpValidator(''), isNotNull);
      expect(otpValidator(null), isNotNull);
    });
  });
}
