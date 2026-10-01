import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/utils/helpers.dart';

void main() {
  test('formats amounts with separators and two decimal places', () {
    const cases = {
      '0': '0.00',
      '5': '5.00',
      '05': '5.00',
      '1500': '1,500.00',
      '1500.00': '1,500.00',
      '10.5': '10.50',
      '10.75': '10.75',
      '1,234.567': '1,234.57',
      '1234567.8': '1,234,567.80',
      '-2500': '-2,500.00',
      ' 750 ': '750.00',
    };

    for (final MapEntry(key: input, value: expected) in cases.entries) {
      expect(formatAmount(input), expected, reason: input);
    }
  });

  test('leaves text that is not a number as it is', () {
    expect(formatAmount('N/A'), 'N/A');
    expect(formatAmount(''), '');
    expect(formatAmount(null), '');
  });
}
