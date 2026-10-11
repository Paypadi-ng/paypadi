import 'package:dio/dio.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/data/authentication/i_authentication_client.dart';

import 'package:retrofit/retrofit.dart';

part 'authentication_client.g.dart';

const String _basePath = '/auth';

@RestApi()
abstract class AuthenticationClient implements IAuthenticationClient {
  factory AuthenticationClient(
    Dio dio, {
    String baseUrl,
  }) = _AuthenticationClient;

  @override
  @POST('$_basePath/register/')
  Future<ApiResponse<RegisterResponse>> createAccount({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/login/')
  Future<ApiResponse<LoginResponse>> login({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/otp/request/')
  Future<ApiResponse<RequestOtpResponse>> requestForOTP({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/otp/verify/')
  Future<ApiResponse<VerifyOtpResponse>> verifyOTP({
    @Body() required Map<String, dynamic> payload,
  });
}
