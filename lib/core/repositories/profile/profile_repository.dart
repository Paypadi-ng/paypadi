import 'dart:io';

import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/clients/profile/i_profile_client.dart';
import 'package:paypadi/core/models/user_profile_model/user_profile_model.dart';
import 'package:paypadi/core/repositories/profile/i_profile_repository.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';

class ProfileRepository implements IProfileRepository {
  const ProfileRepository({required IProfileClient client}) : _client = client;
  final IProfileClient _client;

  @override
  FutureApiResultOf<void> setTransactionPin(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<void>>(
      () => _client.setTransactionPin(payload: payload),
    );
    return response;
  }

  @override
  FutureResultOf<ApiResponse<UserProfileModel>> getUser() async {
    final response = await Result.fromAsync<ApiResponse<UserProfileModel>>(
      _client.getUser,
    );
    return response;
  }

  @override
  FutureResultOf<dynamic> getDriverProfile() async {
    final response = await Result.fromAsync(
      _client.getDriverProfile,
    );
    return response;
  }

  @override
  FutureApiResultOf<DriverProfileModel> createDriverProfile(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<DriverProfileModel>>(
      () => _client.createDriverProfile(payload: payload),
    );
    return response;
  }

  @override
  FutureApiResultOf<DriverProfileModel> updateDriverProfile(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<DriverProfileModel>>(
      () => _client.updateDriverProfile(payload: payload),
    );
    return response;
  }

  @override
  FutureResultOf<ApiResponse<DriverProfileModel>> uploadDocument({
    required File file,
    required String fileName,
    required DocumentCategory category,
    required void Function(int, int)? onSendProgress,
  }) async {
    Result<ApiResponse<DriverProfileModel>, Exception> response;

    switch (category) {
      case DocumentCategory.driverLicenseFront:
        response = await Result.fromAsync<ApiResponse<DriverProfileModel>>(
          () => _client.uploadDocument(
            licenseFront: file,
            fileName: fileName,
            onSendProgress: onSendProgress,
          ),
        );
        break;

      case DocumentCategory.driverLicenseBack:
        response = await Result.fromAsync<ApiResponse<DriverProfileModel>>(
          () => _client.uploadDocument(
            licenseBack: file,
            fileName: fileName,
            onSendProgress: onSendProgress,
          ),
        );
        break;

      case DocumentCategory.vehicleLicense:
        response = await Result.fromAsync<ApiResponse<DriverProfileModel>>(
          () => _client.uploadDocument(
            vehicleReg: file,
            fileName: fileName,
            onSendProgress: onSendProgress,
          ),
        );
        break;
    }

    return response;
  }
}
