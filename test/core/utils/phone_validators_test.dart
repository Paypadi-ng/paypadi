import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/utils/validators.dart';

void main() {
  group('phoneNumberValidator (Nigerian)', () {
    test('accepts local format 0XXXXXXXXXX', () {
      expect(phoneNumberValidator('08031234567'), isNull);
    });

    // test('accepts international +234XXXXXXXXXX', () {
    //   expect(phoneNumberValidator('+2348031234567'), isNull);
    // });

    // test('accepts international without plus 234XXXXXXXXXX', () {
    //   expect(phoneNumberValidator('2348031234567'), isNull);
    // });

    // test('accepts 00234XXXXXXXXXX (00 prefix followed by 234)', () {
    //   expect(phoneNumberValidator('002348031234567'), isNull);
    // });

    test('rejects 00 prefix when not followed by 234', () {
      expect(phoneNumberValidator('00448031234567'), isNotNull);
    });

    test('rejects malformed numbers and letters', () {
      expect(phoneNumberValidator('08031abc567'), isNotNull);
      expect(phoneNumberValidator('12345'), isNotNull);
    });

    // test('accepts numbers with separators', () {
    //   expect(phoneNumberValidator('+234 803-123-4567'), isNull);
    //   expect(phoneNumberValidator('(080) 312-34567'), isNull);
    // });
  });
}
