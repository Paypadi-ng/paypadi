import 'package:paypadi/core/providers.dart';
import 'package:paypadi/data/profile/i_profile_client.dart';
import 'package:paypadi/data/profile/i_profile_repository.dart';
import 'package:paypadi/data/profile/profile_client.dart';
import 'package:paypadi/data/profile/profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@riverpod
IProfileClient profileClient(Ref ref) {
  return ProfileClient(ref.watch(dioProvider));
}

@riverpod
IProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(client: ref.watch(profileClientProvider));
}
