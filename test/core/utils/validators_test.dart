import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/utils/validators.dart';

void main() {
  group('plateNumberValidator', () {
    test('accepts 3-letter format (ABC123DE)', () {
      expect(plateNumberValidator('ABC123DE'), isNull);
    });

    // test('accepts 2-letter format (AB123CD)', () {
    //   expect(plateNumberValidator('AB123CD'), isNull);
    // });

    test('accepts lowercase input (abc123de)', () {
      expect(plateNumberValidator('abc123de'), isNull);
    });

    // test('rejects spaced format (ABC 123 DE)', () {
    //   expect(plateNumberValidator('ABC 123 DE'), isNotNull);
    // });

    // test('rejects input with symbols (ABC-123-DE)', () {
    //   expect(plateNumberValidator('ABC-123-DE'), isNotNull);
    // });

    test('rejects empty or null input', () {
      expect(plateNumberValidator(''), isNotNull);
      expect(plateNumberValidator(null), isNotNull);
    });

    test('rejects wrong patterns (A123BCD, ABC12DE)', () {
      expect(plateNumberValidator('A123BCD'), isNotNull);
      expect(plateNumberValidator('ABC12DE'), isNotNull);
    });
  });
}
