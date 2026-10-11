import 'package:dio/dio.dart';
import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/data/session/i_session_client.dart';
import 'package:paypadi/data/session/models/session_response.dart';
import 'package:retrofit/retrofit.dart';

part 'session_client.g.dart';

const String _basePath = '/auth';

@RestApi()
abstract class SessionClient implements ISessionClient {
  factory SessionClient(Dio dio, {String baseUrl}) = _SessionClient;

  @override
  @POST('$_basePath/jwt/token/')
  Future<ApiResponse<void>> getToken({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/jwt/token/refresh/')
  Future<ApiResponse<SessionResponse>> refreshToken({
    @Body() required Map<String, dynamic> payload,
  });

  @override
  @POST('$_basePath/jwt/token/verify/')
  Future<ApiResponse<String>> verifyToken({
    @Body() required Map<String, dynamic> payload,
  });
}
