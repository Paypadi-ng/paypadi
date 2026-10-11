import 'package:paypadi/core/providers.dart';
import 'package:paypadi/data/session/i_session_client.dart';
import 'package:paypadi/data/session/i_session_repository.dart';
import 'package:paypadi/data/session/session_client.dart';
import 'package:paypadi/data/session/session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
ISessionClient sessionClient(Ref ref) {
  return SessionClient(ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
ISessionRepository sessionRepository(Ref ref) {
  return SessionRepository(client: ref.watch(sessionClientProvider));
}
