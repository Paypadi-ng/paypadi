import 'package:paypadi/core/providers.dart';
import 'package:paypadi/data/authentication/authentication_client.dart';
import 'package:paypadi/data/authentication/authentication_repository.dart';
import 'package:paypadi/data/authentication/i_authentication_client.dart';
import 'package:paypadi/data/authentication/i_authentication_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
IAuthenticationClient authenticationClient(Ref ref) {
  return AuthenticationClient(ref.watch(dioProvider));
}

@riverpod
IAuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository(
    client: ref.watch(authenticationClientProvider),
  );
}
