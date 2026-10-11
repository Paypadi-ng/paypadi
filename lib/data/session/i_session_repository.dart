import 'package:paypadi/core/utils/typedefs.dart';
import 'package:paypadi/data/session/models/session_response.dart';

abstract interface class ISessionRepository {
  FutureApiResultOf<SessionResponse> refreshTokens(
    String refreshToken,
  );
}
