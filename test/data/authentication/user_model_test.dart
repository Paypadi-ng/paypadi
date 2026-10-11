import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/data/authentication/models/user_model.dart';

UserModel user({bool? isDriver, bool? isApproved, String? licensePlate}) =>
    UserModel(
      id: 'u1',
      role: isDriver == true ? 'driver' : 'rider',
      phoneNumber: '08031234567',
      firstName: 'Ada',
      lastName: 'Obi',
      isActive: true,
      phoneVerified: true,
      dateJoined: DateTime.utc(2026, 10, 2),
      isDriver: isDriver,
      isApproved: isApproved,
      licensePlate: licensePlate,
    );

void main() {
  group('needsVehicleInfo', () {
    test('holds back a driver who is not approved and has no vehicle '
        'details', () {
      expect(user(isDriver: true, isApproved: false).needsVehicleInfo, isTrue);
      expect(user(isDriver: true).needsVehicleInfo, isTrue);
    });

    test('lets through a driver whose details are in and awaiting '
        'approval', () {
      expect(
        user(
          isDriver: true,
          isApproved: false,
          licensePlate: 'LND-123-AB',
        ).needsVehicleInfo,
        isFalse,
      );
    });

    test('lets through approved drivers and riders', () {
      expect(user(isDriver: true, isApproved: true).needsVehicleInfo, isFalse);
      expect(user(isDriver: false).needsVehicleInfo, isFalse);
      expect(user().needsVehicleInfo, isFalse);
    });
  });
}
