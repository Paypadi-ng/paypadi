import 'dart:async';

import 'package:paypadi/config/provider_registry/provider_registry.dart';
import 'package:paypadi/config/router/router.gr.dart';
import 'package:paypadi/core/repositories/authentication/i_authentication_repository.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:paypadi/core/utils/extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'authentication_controller.g.dart';

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
          _saveToCache(CacheKeys.password, password),
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
        await _saveSession(
          refreshToken: response.data.refreshToken,
          accessToken: response.data.accessToken,
          refreshExpiry: response.data.refreshTokenExpiry,
          accessExpiry: response.data.accessTokenExpiry,
        );

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

  Future<void> loginWithBiometrics() async {
    final biometricService = ref.read(biometricsProvider);

    try {
      final bool didAuthenticate = await biometricService.authenticate();

      if (didAuthenticate) {
        final String? phoneNumber = await ref
            .read(secureCacheProvider)
            .get<String?>(CacheKeys.phoneNumber);

        final String? password = await ref
            .read(secureCacheProvider)
            .get<String?>(CacheKeys.password);

        if (phoneNumber == null || password == null) {
          return;
        }

        await login(phoneNumber, password);
      }
    } on Exception catch (exception) {
      // Changed to catch Exception strictly, per your lint rules
      ref.showExceptionMessage(exception);
      state = const AsyncData(null);
    }
  }

  Future<void> logout() async {
    final localCache = await ref.read(localCacheProvider.future);

    await Future.wait([
      localCache.clear(),
      ref.read(secureCacheProvider).clear(),
    ]);

    if (!ref.mounted) return;

    unawaited(
      ref
          .read(appRouterProvider)
          .pushAndPopUntil(
            const OnboardingRoute(),
            predicate: (route) => route.settings.name == '/',
          ),
    );
  }

  Future<void> _saveToCache(String key, String? value) async {
    await ref.read(secureCacheProvider).save(key: key, value: value);
  }

  Future<void> _saveSession({
    required String refreshToken,
    required String accessToken,
    required int refreshExpiry,
    required int accessExpiry,
  }) async {
    // FIX: Execute all cache saves concurrently, and actually save the expiry timestamps!
    await Future.wait([
      ref
          .read(secureCacheProvider)
          .save(key: CacheKeys.refreshToken, value: refreshToken),
      ref
          .read(secureCacheProvider)
          .save(key: CacheKeys.accessToken, value: accessToken),
      ref
          .read(secureCacheProvider)
          .save(key: CacheKeys.accessTokenExpiry, value: accessExpiry),
      ref
          .read(secureCacheProvider)
          .save(key: CacheKeys.refreshTokenExpiry, value: refreshExpiry),
    ]);
  }
}
