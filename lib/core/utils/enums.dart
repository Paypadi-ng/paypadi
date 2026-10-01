enum AccountRole {
  passenger(
    title: 'I’m a Passenger',
    description:
        'For individuals who want to book and pay for rides effortlessly.',
  ),
  driver(
    title: 'I’m a Driver',
    description:
        'For drivers who want to manage ride requests, track earnings, and optimize their trips.',
  );

  const AccountRole({required this.title, required this.description});
  final String title;
  final String description;
}

enum AccountType { rider, driver, unknown }

enum PickedAmount {
  two(value: '200'),
  four(value: '400'),
  six(value: '600'),
  eight(value: '800'),
  ten(value: '1000');

  const PickedAmount({required this.value});
  final String value;
}

enum BeneficiaryType {
  recent(typeName: 'Recent'),
  saved(typeName: 'Saved');

  const BeneficiaryType({required this.typeName});
  final String typeName;
}

enum TransactionStatus { success, pending, completed, failure }

/// Transaction kinds the API sends in `transaction_type`.
enum TransactionType {
  transfer,
  deposit,
  withdrawal,
  refund,
  reversal,
  fee,
  reservation,
  adjustment,
  unknown;

  /// Whether the transaction moved money into the wallet (`true`) or out of
  /// it (`false`). `null` when the type alone doesn't say: a reservation
  /// holds funds without moving them, and an adjustment can go either way.
  bool? get isCredit => switch (this) {
    deposit || refund || reversal => true,
    transfer || withdrawal || fee => false,
    reservation || adjustment || unknown => null,
  };
}

enum UploadStatus { idle, uploading, complete, failed }

enum DocumentCategory {
  driverLicenseFront('Driver’s License (Front)'),
  driverLicenseBack('Driver’s License (Back)'),
  vehicleLicense('Vehicle License');

  const DocumentCategory(this.title);
  final String title;
}
