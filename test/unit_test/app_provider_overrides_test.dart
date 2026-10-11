import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:paypadi/app/providers.dart';
import 'package:paypadi/app/session/session_controller.dart';
import 'package:paypadi/core/providers.dart';

/// Stands in for the real session so renewal can be observed without the
/// refresh timer, storage or network.
class _RecordingSession extends SessionController {
  int renewals = 0;

  @override
  FutureOr<void> build() {}

  @override
  Future<bool> renewSession() async {
    renewals++;
    return true;
  }
}

void main() {
  test('a container without the app overrides fails loudly on renewal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(() => container.read(sessionRenewerProvider), throwsA(anything));
  });

  test(
    'the app overrides send 401 renewal to the session controller',
    () async {
      final session = _RecordingSession();
      final container = ProviderContainer(
        overrides: [
          ...appProviderOverrides,
          sessionControllerProvider.overrideWith(() => session),
        ],
      );
      addTearDown(container.dispose);

      final renew = container.read(sessionRenewerProvider);

      expect(await renew(), isTrue);
      expect(session.renewals, 1);
    },
  );
}
