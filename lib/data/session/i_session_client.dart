import 'package:paypadi/core/api/response/api_response.dart';

abstract interface class ISessionClient {
  Future<ApiResponse<void>> getToken({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<SessionResponse>> refreshToken({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<String>> verifyToken({
    required Map<String, dynamic> payload,
  });
}
