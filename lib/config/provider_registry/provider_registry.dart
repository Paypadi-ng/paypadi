import 'dart:ui' show Color;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:paypadi/config/env.dart';
import 'package:paypadi/config/router/router.dart' show AppRouter;
import 'package:paypadi/config/theme.dart' show AppTheme;
import 'package:paypadi/core/clients/authentication/authentication_client.dart';
import 'package:paypadi/core/clients/authentication/i_authentication_client.dart';
import 'package:paypadi/core/clients/payout_account/i_payout_account_client.dart';
import 'package:paypadi/core/clients/payout_account/payout_account_client.dart';
import 'package:paypadi/core/clients/profile/i_profile_client.dart';
import 'package:paypadi/core/clients/profile/profile_client.dart';
import 'package:paypadi/core/clients/session/i_session_client.dart';
import 'package:paypadi/core/clients/session/session_client.dart';
import 'package:paypadi/core/clients/transaction/i_transaction_client.dart';
import 'package:paypadi/core/clients/transaction/transaction_client.dart';
import 'package:paypadi/core/clients/wallet/i_wallet_client.dart';
import 'package:paypadi/core/clients/wallet/wallet_client.dart';
import 'package:paypadi/core/repositories/authentication/authentication_repository.dart';
import 'package:paypadi/core/repositories/authentication/i_authentication_repository.dart';
import 'package:paypadi/core/repositories/payout_account/i_payout_account_repository.dart';
import 'package:paypadi/core/repositories/payout_account/payout_account_repository.dart';
import 'package:paypadi/core/repositories/profile/i_profile_repository.dart';
import 'package:paypadi/core/repositories/profile/profile_repository.dart';
import 'package:paypadi/core/repositories/session/i_session_repository.dart';
import 'package:paypadi/core/repositories/session/session_repository.dart';
import 'package:paypadi/core/repositories/transaction/i_transaction_repository.dart';
import 'package:paypadi/core/repositories/transaction/transaction_repository.dart';
import 'package:paypadi/core/repositories/wallet/i_wallet_repository.dart';
import 'package:paypadi/core/repositories/wallet/wallet_repository.dart';
import 'package:paypadi/core/services/api_service.dart';
import 'package:paypadi/core/services/app_version_service.dart';
import 'package:paypadi/core/services/asset_share_service.dart';
import 'package:paypadi/core/services/biometrics_service.dart';
import 'package:paypadi/core/services/file_picker_service.dart';
import 'package:paypadi/core/services/image_picker_service.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/monitoring/sentry_service.dart';
import 'package:paypadi/core/services/notifications/firebase_notifications_service.dart';
import 'package:paypadi/core/services/notifications/notifications_service.dart';
import 'package:paypadi/core/services/receipt_service.dart';
import 'package:paypadi/core/services/storage/local_cache_service.dart';
import 'package:paypadi/core/services/storage/secure_cache_service.dart';
import 'package:paypadi/core/utils/constants.dart' show availableColors;
import 'package:paypadi/src/shared/controllers/app_color/app_color_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesWithCache, SharedPreferencesWithCacheOptions;

part 'provider_registry.g.dart';

// =============================================================================
// Core & Infrastructure Services
// =============================================================================

@Riverpod(keepAlive: true)
MonitoringService monitoring(Ref ref) {
  return SentryMonitoringService();
}

@Riverpod(keepAlive: true)
Future<SharedPreferencesWithCache> sharedPreferencesFuture(Ref ref) {
  return SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
}

@Riverpod(keepAlive: true)
SecureCacheService secureCache(Ref ref) {
  return SecureCacheService(monitoring: ref.watch(monitoringProvider));
}

@Riverpod(keepAlive: true)
Future<LocalCacheService> localCache(Ref ref) async {
  final monitoring = ref.watch(monitoringProvider);
  final prefs = await ref.watch(sharedPreferencesFutureProvider.future);

  return LocalCacheService(
    sharedPreferences: prefs,
    monitoring: monitoring,
  );
}

@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(Ref ref) {
  return FirebaseMessaging.instance;
}

@Riverpod(keepAlive: true)
INotificationsService notificationsService(Ref ref) {
  return FirebaseNotificationsService(ref.watch(firebaseMessagingProvider));
}

// =============================================================================
// Theme & UI Configurations
// =============================================================================

@Riverpod(keepAlive: true)
Color appPrimaryColor(Ref ref) {
  // Watch the async state of the color index
  final colorIndexAsync = ref.watch(colorIndexProvider);

  // Map the index to the color, defaulting to the first color if loading/error
  return colorIndexAsync.maybeWhen(
    data: (index) => availableColors[index],
    orElse: () => availableColors[0],
  );
}

@Riverpod(keepAlive: true)
AppTheme appTheme(Ref ref) {
  return AppTheme(primary: ref.watch(appPrimaryColorProvider));
}

@Riverpod(keepAlive: true)
AppRouter appRouter(Ref ref) {
  return AppRouter(ref: ref);
}

// =============================================================================
// Network & API Clients
// =============================================================================

@Riverpod(keepAlive: true)
ApiService apiService(Ref ref) {
  return ApiService(
    cacheService: ref.watch(secureCacheProvider),
    baseUrl: AppEnvironment.backendApiBaseUrl,
  );
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return ref.watch(apiServiceProvider).dio;
}

@riverpod
IAuthenticationClient authenticationClient(Ref ref) {
  return AuthenticationClient(ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
ISessionClient sessionClient(Ref ref) {
  return SessionClient(ref.watch(dioProvider));
}

@riverpod
IPayoutAccountClient payoutAccountClient(Ref ref) {
  return PayoutAccountClient(ref.watch(dioProvider));
}

@riverpod
IProfileClient profileClient(Ref ref) {
  return ProfileClient(ref.watch(dioProvider));
}

@riverpod
IWalletClient walletClient(Ref ref) {
  return WalletClient(ref.watch(dioProvider));
}

@riverpod
ITransactionClient transactionClient(Ref ref) {
  return TransactionClient(ref.watch(dioProvider));
}

// =============================================================================
// Repositories
// =============================================================================

@riverpod
IAuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository(
    client: ref.watch(authenticationClientProvider),
  );
}

@Riverpod(keepAlive: true)
ISessionRepository sessionRepository(Ref ref) {
  return SessionRepository(client: ref.watch(sessionClientProvider));
}

@riverpod
IPayoutAccountRepository payoutAccountRepository(Ref ref) {
  return PayoutAccountRepository(
    client: ref.watch(payoutAccountClientProvider),
  );
}

@riverpod
IProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(client: ref.watch(profileClientProvider));
}

@riverpod
IWalletRepository walletRepository(Ref ref) {
  return WalletRepository(client: ref.watch(walletClientProvider));
}

@riverpod
ITransactionRepository transactionRepository(Ref ref) {
  return TransactionRepository(client: ref.watch(transactionClientProvider));
}

// =============================================================================
// Platform Utilities & Device Services
// =============================================================================

@Riverpod(keepAlive: true)
BiometricsService biometrics(Ref ref) {
  return BiometricsService();
}

@riverpod
ReceiptService receiptService(Ref ref) {
  return ReceiptService();
}

@riverpod
FilePickerService filePickerService(Ref ref) {
  return FilePickerService();
}

@riverpod
ImagePickerService imagePickerService(Ref ref) {
  return ImagePickerService();
}

@riverpod
AppVersionService appVersionService(Ref ref) {
  return AppVersionService();
}

@riverpod
AssetShareService assetShareService(Ref ref) {
  return AssetShareService();
}
