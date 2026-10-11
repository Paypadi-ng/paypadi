import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:paypadi/core/api/api_service.dart';
import 'package:paypadi/core/env.dart';
import 'package:paypadi/core/services/device/app_version_service.dart';
import 'package:paypadi/core/services/device/asset_share_service.dart';
import 'package:paypadi/core/services/device/biometrics_service.dart';
import 'package:paypadi/core/services/device/file_picker_service.dart';
import 'package:paypadi/core/services/device/image_picker_service.dart';
import 'package:paypadi/core/services/device/receipt_service.dart';
import 'package:paypadi/core/services/device/url_launcher_service.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/monitoring/sentry_service.dart';
import 'package:paypadi/core/services/notifications/firebase_notifications_service.dart';
import 'package:paypadi/core/services/notifications/notifications_service.dart';
import 'package:paypadi/core/services/storage/local_cache_service.dart';
import 'package:paypadi/core/services/storage/secure_cache_service.dart';
import 'package:paypadi/core/services/storage/transaction_pin_vault.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesWithCache, SharedPreferencesWithCacheOptions;

part 'providers.g.dart';

/// Renews the session after a request is rejected with 401, returning
/// whether the session is usable afterwards.
typedef SessionRenewer = Future<bool> Function();

/// Returns the current time.
typedef Clock = DateTime Function();

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
TransactionPinVault transactionPinVault(Ref ref) {
  return TransactionPinVault(monitoring: ref.watch(monitoringProvider));
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

/// The current time. Tests override it to move time forward.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;

// =============================================================================
// Network
// =============================================================================

/// The session lives in the app layer, which core can't import, so the app
/// supplies this through `appProviderOverrides` (see `app/providers.dart`).
@Riverpod(keepAlive: true)
SessionRenewer sessionRenewer(Ref ref) {
  throw UnimplementedError(
    'sessionRenewerProvider must be overridden: create the ProviderContainer '
    'with appProviderOverrides.',
  );
}

@Riverpod(keepAlive: true)
ApiService apiService(Ref ref) {
  return ApiService(
    cacheService: ref.watch(secureCacheProvider),
    baseUrl: AppEnvironment.backendApiBaseUrl,
    // Read when a request is rejected, not now: the session controller
    // itself depends on this service.
    renewSession: () => ref.read(sessionRenewerProvider)(),
  );
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return ref.watch(apiServiceProvider).dio;
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
  return AppVersionService(monitoring: ref.watch(monitoringProvider));
}

@riverpod
AssetShareService assetShareService(Ref ref) {
  return AssetShareService();
}

@riverpod
UrlLauncherService urlLauncher(Ref ref) {
  return const UrlLauncherService();
}
