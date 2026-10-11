import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/authentication/i_authentication_client.dart';
import 'package:paypadi/data/authentication/i_authentication_repository.dart';

class AuthenticationRepository implements IAuthenticationRepository {
  const AuthenticationRepository({required IAuthenticationClient client})
    : _client = client;
  final IAuthenticationClient _client;

  @override
  FutureApiResultOf<RegisterResponse> createAccount(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<RegisterResponse>>(
      () => _client.createAccount(payload: payload),
    );
    return response;
  }

  @override
  FutureResultOf<ApiResponse<LoginResponse>> login(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<LoginResponse>>(
      () => _client.login(payload: payload),
    );
    return response;
  }

  @override
  FutureApiResultOf<RequestOtpResponse> requestForOtpCode(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<RequestOtpResponse>>(
      () => _client.requestForOTP(payload: payload),
    );
    return response;
  }

  @override
  FutureApiResultOf<VerifyOtpResponse> verifyOtpCode(
    Map<String, dynamic> payload,
  ) async {
    final response = await Result.fromAsync<ApiResponse<VerifyOtpResponse>>(
      () => _client.verifyOTP(payload: payload),
    );
    return response;
  }
}
