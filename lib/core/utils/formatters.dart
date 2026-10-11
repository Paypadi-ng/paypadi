import 'package:paypadi/core/utils/enums.dart';

/// Formats an amount for display with thousands separators and two decimal
/// places: "1500" → "1,500.00", "10.5" → "10.50", "1,234.567" → "1,234.57".
/// Text that isn't a number is returned trimmed but otherwise unchanged.
String formatAmount(String? amount) {
  if (amount == null || amount.trim().isEmpty) return '';

  final trimmed = amount.trim();
  final value = num.tryParse(trimmed.replaceAll(',', ''));
  if (value == null) return trimmed;

  final [whole, fraction] = value.abs().toStringAsFixed(2).split('.');
  final grouped = whole.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  return '${value < 0 ? '-' : ''}$grouped.$fraction';
}

String capitalizeFirstChar(String? s) {
  if (s == null || s.trim().isEmpty) return '';

  final value = s.trim();
  if (value.length == 1) return value.toUpperCase();

  return value[0].toUpperCase() + value.substring(1);
}

String getInitials(String fullName) {
  final trimmedName = fullName.trim();
  if (trimmedName.isEmpty) return '';

  final parts = trimmedName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    final word = parts.first;
    if (word.length == 1) return word.toUpperCase();
    return word.substring(0, 2).toUpperCase();
  }

  final firstInitial = parts.first[0];
  final lastInitial = parts.last[0];
  return '$firstInitial$lastInitial'.toUpperCase();
}

String obfuscatePhoneNumber(String phoneNumber) {
  // Remove any spaces, dashes, or other formatting
  final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

  // Handle different Nigerian phone number formats
  String digits = cleaned;

  // Remove country code if present (+234 or 234)
  if (digits.startsWith('+234')) {
    digits = digits.substring(4);
  } else if (digits.startsWith('234')) {
    digits = digits.substring(3);
  }

  // Nigerian mobile numbers should be 11 digits starting with 0
  // or 10 digits without the leading 0
  if (digits.length == 10 && !digits.startsWith('0')) {
    digits = '0$digits'; // Add leading 0 if missing
  }

  // Validate Nigerian mobile number format
  if (digits.length != 11 || !digits.startsWith('0')) {
    return phoneNumber; // Return original if invalid format
  }

  // Nigerian mobile prefixes (080, 081, 070, 090, 091, etc.)
  final validPrefixes = ['080', '081', '070', '090', '091', '070', '071'];
  final prefix = digits.substring(0, 3);

  if (!validPrefixes.contains(prefix)) {
    return phoneNumber; // Return original if invalid prefix
  }

  // Format: 081 **** 6507 (show first 3 and last 4 digits)
  final firstPart = digits.substring(0, 3); // 081
  final lastPart = digits.substring(7); // 6507
  final obfuscated = '*' * 4; // ****

  return '$firstPart $obfuscated $lastPart';
}

String getTransactionDirectionLabel(TransactionType type) {
  return switch (type.isCredit) {
    true => 'From',
    false => 'To',
    null => '?',
  };
}
