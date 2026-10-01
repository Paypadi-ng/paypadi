import 'dart:async';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/api/exceptions/server_exception.dart';
import 'package:paypadi/core/repositories/authentication/i_authentication_repository.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:paypadi/core/utils/helpers.dart' show jwtExpiry;
import 'package:paypadi/src/shared/controllers/app_toast/app_toast_controller.dart';
import 'package:paypadi/src/shared/controllers/session/session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'authentication_controller.g.dart';

/// Shown when biometric unlock can't renew the session.
const sessionExpiredMessage =
    'Your session has expired. Enter your password to sign in.';

@Riverpod(keepAlive: true)
Map<String, dynamic> authenticationPayload(Ref ref) => <String, dynamic>{};

@riverpod
class AuthenticationController extends _$AuthenticationController {
  late final IAuthenticationRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(authenticationRepositoryProvider);
  }

  Future<void> login(String phoneNumber, String password) async {
    state = const AsyncLoading();
    final result = await _repository.login({
      'phone_number': phoneNumber,
      'password': password,
    });

    await result.fold(
      (response) async {
        await Future.wait([
          ref.read(notificationsServiceProvider).requestPermission(),
          _saveSession(
            refreshToken: response.data.refreshToken,
            accessToken: response.data.accessToken,
            refreshExpiry: response.data.refreshTokenExpiry,
            accessExpiry: response.data.accessTokenExpiry,
          ),

          _saveToCache(CacheKeys.email, response.data.user.email),
          _saveToCache(CacheKeys.firstName, response.data.user.firstName),
          _saveToCache(CacheKeys.phoneNumber, phoneNumber),
          _forgetLegacyCredentials(),
        ]);

        // Note: It is safer to use unawaited() for listeners or route pushes
        // to prevent blocking the UI thread unnecessarily.
        ref.read(notificationsServiceProvider).onTokenRefresh.listen((token) {
          token.printLog();
        });

        state = const AsyncData(null);
        unawaited(ref.read(appRouterProvider).push(const DashboardRoute()));
      },
      (exception) {
        ref.showExceptionMessage(exception);
        state = const AsyncData(null);
      },
    );
  }

  Future<void> register() async {
    state = const AsyncLoading();

    final payload = ref.read(authenticationPayloadProvider);
    final result = await _repository.createAccount(payload);

    await result.fold(
      (response) async {
        // Registration doesn't return expiry fields; read them from the JWTs.
        await _saveSession(
          refreshToken: response.data.refreshToken,
          accessToken: response.data.accessToken,
          refreshExpiry: jwtExpiry(response.data.refreshToken),
          accessExpiry: jwtExpiry(response.data.accessToken),
        );

        // The account exists now; drop the sign-up details, password
        // included, rather than keep them in memory for the session.
        ref.invalidate(authenticationPayloadProvider);

        state = const AsyncData(null);
        unawaited(
          ref.read(appRouterProvider).push(const CreateTransactionPinRoute()),
        );
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }

  Future<void> requestForOtp() async {
    state = const AsyncLoading();
    final payloadBuilder = ref.read(authenticationPayloadProvider);
    final result = await _repository.requestForOtpCode({
      'phone_number': payloadBuilder['phone_number'],
      'purpose': 'registration',
    });

    await result.fold(
      (success) async {
        state = const AsyncData(null);
        unawaited(ref.read(appRouterProvider).push(const OtpRoute()));
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }

  Future<void> verifyOtpCode(String code) async {
    state = const AsyncLoading();
    final payloadBuilder = ref.read(authenticationPayloadProvider);
    final result = await _repository.verifyOtpCode({
      'phone_number': payloadBuilder['phone_number'],
      'purpose': 'registration',
      'code': code,
    });

    await result.fold(
      (success) async {
        // Update the central payload state
        ref.read(authenticationPayloadProvider)['phone_token'] =
            success.data.token;

        state = const AsyncData(null);
        unawaited(ref.read(appRouterProvider).push(const AccountRoleRoute()));
      },
      (failure) {
        ref.showExceptionMessage(failure);
        state = const AsyncData(null);
      },
    );
  }

  /// Quick unlock: after a biometric check, renews the stored session with
  /// its refresh token. No password is kept on the device, so once the
  /// refresh token has expired the user signs in with their password.
  Future<void> unlockWithBiometrics() async {
    if (state.isLoading) return;

    final bool didAuthenticate;
    try {
      didAuthenticate = await ref.read(biometricsProvider).authenticate();
    } on Exception catch (exception) {
      if (ref.mounted) ref.showExceptionMessage(exception);
      return;
    }
    if (!didAuthenticate || !ref.mounted) return;

    state = const AsyncLoading();
    try {
      await ref.read(sessionControllerProvider.notifier).refreshToken();
    } on Exception catch (exception) {
      if (!ref.mounted) return;
      state = const AsyncData(null);
      if (_isSessionOver(exception)) {
        ref
            .read(appToastControllerProvider.notifier)
            .showError(sessionExpiredMessage);
      } else {
        ref.showExceptionMessage(exception);
      }
      return;
    }

    await _forgetLegacyCredentials();
    if (!ref.mounted) return;

    state = const AsyncData(null);
    unawaited(ref.read(appRouterProvider).push(const DashboardRoute()));
  }

  /// No refresh token, or one the server rejected: biometrics can't unlock
  /// the account any more and the password is needed.
  bool _isSessionOver(Exception exception) =>
      exception is ServerException &&
      exception.maybeMap(
        unauthorizedRequest: (_) => true,
        forbiddenRequest: (_) => true,
        orElse: () => false,
      );

  /// Deletes the password and transaction PIN that older versions stored.
  Future<void> _forgetLegacyCredentials() async {
    final cache = ref.read(secureCacheProvider);
    await Future.wait([
      cache.remove(CacheKeys.legacyPassword),
      cache.remove(CacheKeys.legacyTransactionPin),
    ]);
  }

  Future<void> _saveToCache(String key, String? value) async {
    await ref.read(secureCacheProvider).save(key: key, value: value);
  }

  Future<void> _saveSession({
    required String refreshToken,
    required String accessToken,
    int? refreshExpiry,
    int? accessExpiry,
  }) async {
    // FIX: Execute all cache saves concurrently, and actually save the expiry timestamps!
    await Future.wait([
      ref
          .read(secureCacheProvider)
          .save(key: CacheKeys.refreshToken, value: refreshToken),
      ref
          .read(secureCacheProvider)
          .save(key: CacheKeys.accessToken, value: accessToken),
      if (accessExpiry != null)
        ref
            .read(secureCacheProvider)
            .save(key: CacheKeys.accessTokenExpiry, value: accessExpiry),
      if (refreshExpiry != null)
        ref
            .read(secureCacheProvider)
            .save(key: CacheKeys.refreshTokenExpiry, value: refreshExpiry),
    ]);
  }
}
