import 'dart:io';

import 'package:dio/dio.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/models/user_profile_model/user_profile_model.dart';

abstract interface class IProfileClient {
  Future<ApiResponse<dynamic>> getRider();

  Future<ApiResponse<dynamic>> updateRider();

  Future<ApiResponse<dynamic>> partiallyUpdateRider();

  Future<ApiResponse<DriverProfileModel>> getDriverProfile();

  Future<ApiResponse<DriverProfileModel>> createDriverProfile({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<DriverProfileModel>> updateDriverProfile({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<UserProfileModel>> getUser();

  Future<ApiResponse<void>> setTransactionPin({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<dynamic>> changePassword({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<DriverProfileModel>> uploadDocument({
    required String fileName,
    File? licenseFront,
    File? licenseBack,
    File? vehicleReg,
    ProgressCallback? onSendProgress,
  });
}
