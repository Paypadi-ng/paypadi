import 'package:paypadi/core/api/response/api_response.dart';

abstract interface class IAuthenticationClient {
  Future<ApiResponse<RegisterResponse>> createAccount({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<LoginResponse>> login({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<RequestOtpResponse>> requestForOTP({
    required Map<String, dynamic> payload,
  });

  Future<ApiResponse<VerifyOtpResponse>> verifyOTP({
    required Map<String, dynamic> payload,
  });
}
