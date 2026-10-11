import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String role,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'verified_phone') required bool phoneVerified,
    @JsonKey(name: 'date_joined') required DateTime dateJoined,
    String? email,
    @JsonKey(name: 'is_driver') bool? isDriver,
    @JsonKey(name: 'driver_id') String? driverId,
    @JsonKey(name: 'is_approved') bool? isApproved,
    @JsonKey(name: 'license_plate') String? licensePlate,
    @JsonKey(name: 'vehicle_model') String? vehicleModel,
    @JsonKey(name: 'driver_license_number') String? driverLicenseNumber,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
