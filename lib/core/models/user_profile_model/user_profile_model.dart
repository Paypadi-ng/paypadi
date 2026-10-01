import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paypadi/core/utils/enums.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
sealed class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String id,
    @JsonKey(unknownEnumValue: AccountType.unknown) required AccountType role,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'verified_phone') required bool phoneVerified,
    @JsonKey(name: 'date_joined') required String dateJoined,
    @JsonKey(name: 'total_referrals', fromJson: _intFromJson)
    required int totalReferrals,
    @JsonKey(name: 'referral_code') String? referralCode,
    String? email,
    @JsonKey(name: 'is_driver', fromJson: _boolFromJson) bool? isDriver,
    @JsonKey(name: 'last_login') String? lastLogin,
    @JsonKey(name: 'kyc_status') String? kycStatus,
    ProfileModel? profile,
    @JsonKey(name: 'driver_profile') DriverProfileModel? driverProfile,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}

@freezed
sealed class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required int id,
    @JsonKey(name: 'is_email_verified') required bool emailVerified,
    String? address,
    String? city,
    String? state,
    String? country,
    @JsonKey(name: 'date_of_birth') String? dob,
    @JsonKey(name: 'profile_picture') String? profilePicture,
    @JsonKey(name: 'id_document') String? idDocument,
    @JsonKey(name: 'id_document_type') String? idDocumentType,
    @JsonKey(name: 'id_document_number') String? idDocumentNumber,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

@freezed
sealed class DriverProfileModel with _$DriverProfileModel {
  const factory DriverProfileModel({
    required int id,
    @JsonKey(name: 'total_rides') required int totalRides,
    @JsonKey(name: 'is_approved') required bool isApproved,
    @JsonKey(name: 'is_available') required bool isAvailable,
    @JsonKey(name: 'submitted_for_approval') required bool submittedForApproval,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    // A driver fills these in after sign-up, so a new profile has none yet.
    @JsonKey(name: 'vehicle_make') String? vehicleMake,
    @JsonKey(name: 'vehicle_model') String? vehicleModel,
    @JsonKey(name: 'vehicle_year') int? vehicleYear,
    @JsonKey(name: 'license_plate') String? licensePlate,
    @JsonKey(name: 'driver_license_number') String? licenseNumber,
    @JsonKey(name: 'driver_license_expiry') String? licenseExpiryDate,
    @JsonKey(name: 'license_front') String? licenseFrontPicUrl,
    @JsonKey(name: 'license_back') String? licenseBackPicUrl,
    @JsonKey(name: 'vehicle_registration') String? vehicleRegistrationPicUrl,
    @JsonKey(name: 'approved_at') String? approvedAt,
    @JsonKey(name: 'rejection_reason') String? reasonForRejection,
  }) = _DriverProfileModel;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileModelFromJson(json);
}

/// The API schema types `total_referrals` as a string; accept a number or a
/// numeric string.
int _intFromJson(Object? value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text) ?? 0,
  _ => 0,
};

/// The API schema types `is_driver` as a string; accept a bool or
/// `"true"`/`"false"`.
bool? _boolFromJson(Object? value) => switch (value) {
  final bool flag => flag,
  final String text => text.toLowerCase() == 'true',
  _ => null,
};
