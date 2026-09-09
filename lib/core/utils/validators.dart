// Simple validators used across the app.
String? requiredValidator(String? text) {
  if (text == null || text.trim().isEmpty) return 'This field is required';

  return null;
}

String? pinCodeValidator(String? code) {
  if (code == null || code.trim().isEmpty) return 'Enter your PIN';

  final trimmed = code.trim();

  // Accept only 6-digit numeric PINs
  if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) return 'Enter a valid 6-digit PIN';

  return null;
}

String? nameValidator(String? name) {
  if (name == null || name.trim().isEmpty) return 'Enter a name';

  final trimmed = name.trim();

  // Disallow spaces — only a single (singular) name is allowed.
  if (trimmed.contains(RegExp(r'\s'))) return 'Enter a single name (no spaces)';

  // Accept only ASCII letters. If you want to allow diacritics, we can expand this.
  final RegExp regex = RegExp(r'^[A-Za-z]+$');
  if (!regex.hasMatch(trimmed)) return 'Enter a valid name';

  return null;
}

String? otpValidator(String? otp) {
  if (otp == null || otp.trim().isEmpty) return 'Enter the OTP';
  final trimmed = otp.trim();

  // Accept 4 to 6 digit numeric OTPs (common lengths). Adjust if your app uses a different length.
  if (!RegExp(r'^\d{4,6}$').hasMatch(trimmed)) return 'Enter a valid OTP';

  return null;
}

String? phoneNumberValidator(String? phone) {
  if (phone == null || phone.trim().isEmpty) {
    return 'Enter a phone number';
  }

  // Remove common separators (spaces, dashes, parentheses)
  final normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  // Regex breakdown for industry standard Nigerian numbers:
  // ^(?:\+?234|0) -> Starts with optional '+234', '234', or a single '0'
  // [789][01]\d{8}$ -> Followed by a valid Nigerian mobile prefix (70, 80, 90, 81, etc.) and 8 more digits
  final nigerianPhoneRegex = RegExp(r'^(?:\+?234|0)[789][01]\d{8}$');

  if (!nigerianPhoneRegex.hasMatch(normalized)) {
    return 'Enter a valid Nigerian phone number (e.g., +2348031234567 or 08031234567)';
  }

  return null;
}

String? plateNumberValidator(String? plate) {
  // Validate Nigerian vehicle plate numbers.
  // Standard FRSC format: AAA-000-AA
  // - 3 letters (state/region code), 3 digits, 2 letters
  // - Spaces or dashes between groups are allowed (e.g. "ABC-123-DE" or "ABC 123 DE")

  if (plate == null || plate.trim().isEmpty) {
    return 'Enter a plate number';
  }

  // Normalize: uppercase and strip spaces/dashes used as group separators
  final normalized = plate.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  // Reject anything outside letters and digits after normalization
  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(normalized)) {
    return 'Enter a valid plate number (e.g. ABC 123 DE)';
  }

  // Standard format: 3 letters + 3 digits + 2 letters (e.g. ABC123DE)
  if (!RegExp(r'^[A-Z]{3}\d{3}[A-Z]{2}$').hasMatch(normalized)) {
    return 'Enter a valid Nigerian plate number (e.g. ABC 123 DE)';
  }

  return null;
}

String? accountNumberValidator(String? accountNumber) {
  if (accountNumber == null || accountNumber.trim().isEmpty) {
    return 'Enter an account number';
  }
  final trimmed = accountNumber.trim();
  if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
    return 'Enter a valid account number';
  }
  return null;
}

String? dateValidator(String? date) {
  if (date == null || date.trim().isEmpty) {
    return 'Enter a date';
  }

  final trimmed = date.trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
  if (match == null) return 'Enter a valid date (yyyy-mm-dd)';

  final parsedDate = DateTime.tryParse(trimmed);
  if (parsedDate == null) return 'Enter a valid date (yyyy-mm-dd)';

  final normalized =
      '${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';

  if (normalized != trimmed) return 'Enter a valid date (yyyy-mm-dd)';

  return null;
}
