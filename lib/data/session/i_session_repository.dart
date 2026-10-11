import 'package:paypadi/core/api/response/api_response.dart';
import 'package:paypadi/core/utils/typedefs.dart';

abstract interface class ISessionRepository {
  FutureApiResultOf<SessionResponse> refreshTokens(
    String refreshToken,
  );
}
