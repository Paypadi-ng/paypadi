import 'dart:convert';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:paypadi/config/gen/assets.gen.dart';
import 'package:paypadi/core/utils/enums.dart';

String obfuscateEmail(String email) {
  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
  if (!emailRegex.hasMatch(email)) return email;

  final parts = email.split('@');
  if (parts.length != 2) return email;

  final username = parts[0];
  final domain = parts[1];

  final visible = username.length > 4 ? username.substring(0, 4) : username;
  final obfuscated = '*' * (username.length - visible.length);

  return '$visible$obfuscated@$domain';
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

String formatAmount(String? amount) {
  if (amount == null || amount.trim().isEmpty) return '';

  final normalized = amount.trim();
  final value = normalized.contains('.00') ? normalized : '$normalized.00';

  return value.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

String formatDate(DateTime date) {
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

String capitalizeFirstChar(String? s) {
  if (s == null || s.trim().isEmpty) return '';

  final value = s.trim();
  if (value.length == 1) return value.toUpperCase();

  return value[0].toUpperCase() + value.substring(1);
}

Future<void> preCacheSVGs() async {
  for (final svgIcon in AppAssets.icons.values) {
    final loadSvg = SvgAssetLoader(svgIcon.path);
    await svg.cache.putIfAbsent(
      loadSvg.cacheKey(null),
      () => loadSvg.loadBytes(null),
    );
  }
}

String getDayTime() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'morning';
  } else if (hour >= 12 && hour < 17) {
    return 'afternoon';
  } else {
    return 'evening';
  }
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

String getTransactionDirectionLabel(TransactionType type) {
  return switch (type.isCredit) {
    true => 'From',
    false => 'To',
    null => '?',
  };
}

String getTransactionDate(String? date) {
  if (date == null || date.trim().isEmpty) return '';

  final parsedDate = DateTime.tryParse(date);
  if (parsedDate == null) return date;

  final localDate = parsedDate.toLocal();
  final months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[localDate.month - 1];
  final day = localDate.day.toString().padLeft(2, '0');
  final year = localDate.year.toString();
  final hour24 = localDate.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final hour = hour12.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  final meridiem = hour24 >= 12 ? 'PM' : 'AM';

  return '$month $day, $year, $hour:$minute $meridiem';
}

String getDate(String? date) {
  if (date == null || date.trim().isEmpty) return '';

  final parsedDate = DateTime.tryParse(date);
  if (parsedDate == null) return date;

  final localDate = parsedDate.toLocal();
  final months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final month = months[localDate.month - 1];
  final day = localDate.day;
  final year = localDate.year;

  String suffix;
  if (day >= 11 && day <= 13) {
    suffix = 'th';
  } else {
    suffix = switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }

  return '$month $day$suffix $year';
}

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
