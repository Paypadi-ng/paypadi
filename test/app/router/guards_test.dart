import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/app/router/guards.dart';

void main() {
  final now = DateTime.utc(2026, 10, 11, 12);
  int secondsFromNow(Duration offset) =>
      now.add(offset).millisecondsSinceEpoch ~/ 1000;

  SessionAccess access({
    String? refreshToken = 'refresh',
    Duration? expiresIn = const Duration(hours: 20),
    bool unlocked = false,
  }) => sessionAccess(
    refreshToken: refreshToken,
    refreshExpiry: expiresIn == null ? null : secondsFromNow(expiresIn),
    unlocked: unlocked,
    now: now,
  );

  group('protected routes', () {
    test('are open once a live session has been unlocked', () {
      expect(access(unlocked: true), SessionAccess.allowed);
    });

    test('send a live but locked session to the unlock screen, as when a '
        'protected route is opened straight after launch', () {
      expect(access(), SessionAccess.locked);
    });

    test('need a full sign-in without a session', () {
      expect(access(refreshToken: null), SessionAccess.signedOut);
      expect(access(expiresIn: null), SessionAccess.signedOut);
    });

    test('need a full sign-in once the refresh token has expired, even if '
        'the app was unlocked', () {
      expect(
        access(expiresIn: const Duration(minutes: -1), unlocked: true),
        SessionAccess.signedOut,
      );
      expect(access(expiresIn: Duration.zero), SessionAccess.signedOut);
    });
  });
}
