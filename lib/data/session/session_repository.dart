import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/api/result.dart';
import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/session/i_session_client.dart';
import 'package:paypadi/data/session/i_session_repository.dart';
import 'package:paypadi/data/session/models/session_response.dart';

class SessionRepository implements ISessionRepository {
  const SessionRepository({required ISessionClient client}) : _client = client;
  final ISessionClient _client;

  @override
  FutureApiResultOf<SessionResponse> refreshTokens(String refreshToken) async {
    final payload = <String, dynamic>{'refresh': refreshToken};

    final response = await Result.fromAsync<ApiResponse<SessionResponse>>(
      () => _client.refreshToken(payload: payload),
    );
    return response;
  }
}
