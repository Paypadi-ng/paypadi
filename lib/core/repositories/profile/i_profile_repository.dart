import 'dart:io';

import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/models/user_profile_model/user_profile_model.dart';
import 'package:paypadi/core/utils/enums.dart';
import 'package:paypadi/core/utils/typedefs.dart';

abstract interface class IProfileRepository {
  FutureApiResultOf<void> setTransactionPin(
    Map<String, dynamic> payload,
  );

  FutureResultOf<ApiResponse<UserProfileModel>> getUser();

  FutureResultOf<dynamic> getDriverProfile();

  FutureApiResultOf<DriverProfileModel> createDriverProfile(
    Map<String, dynamic> payload,
  );

  FutureApiResultOf<DriverProfileModel> updateDriverProfile(
    Map<String, dynamic> payload,
  );

  FutureResultOf<ApiResponse<DriverProfileModel>> uploadDocument({
    required File file,
    required String fileName,
    required DocumentCategory category,
    required void Function(int, int)? onSendProgress,
  });
}
