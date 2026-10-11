import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_unlocked.g.dart';

/// Whether the user has proved it's them since the app started, by signing
/// in with their password or unlocking with biometrics.
///
/// Held in memory only: every launch starts locked, even when a valid
/// session is stored, so a protected route can't be opened without passing
/// the unlock screen first. Logging out locks it again, and so does
/// leaving the app in the background for too long (see SessionController).
@Riverpod(keepAlive: true)
class SessionUnlocked extends _$SessionUnlocked {
  @override
  bool build() => false;

  void unlock() => state = true;

  void lock() => state = false;
}
