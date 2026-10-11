import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/utils/typedefs.dart';

abstract interface class IAuthenticationRepository {
  FutureApiResultOf<RegisterResponse> createAccount(
    Map<String, dynamic> payload,
  );

  FutureResultOf<ApiResponse<LoginResponse>> login(
    Map<String, dynamic> payload,
  );

  FutureApiResultOf<RequestOtpResponse> requestForOtpCode(
    Map<String, dynamic> payload,
  );

  FutureApiResultOf<VerifyOtpResponse> verifyOtpCode(
    Map<String, dynamic> payload,
  );
}
