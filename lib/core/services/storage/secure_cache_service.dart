import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paypadi/core/api/exceptions/app_exception.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/storage/cache_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:talker_flutter/talker_flutter.dart' show Talker;

/// [CacheService] backed by [FlutterSecureStorage].
///
/// Only `String` values are supported; attempting to save other types logs an
/// error and is a no-op. Use this for tokens, secrets, and sensitive user data.
class SecureCacheService implements CacheService {
  SecureCacheService({
    required MonitoringService monitoring,
    FlutterSecureStorage? storage,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             // 1. Android encrypted preferences fallback to prevent Keystore crashes
             aOptions: AndroidOptions.biometric(),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           ),
       _monitoring = monitoring;

  final Talker _logger = debugLogger;
  final MonitoringService _monitoring;
  final FlutterSecureStorage _storage;

  @override
  Future<T?> get<T>(String key, [T Function(dynamic raw)? parser]) async {
    try {
      final String? value = await _storage.read(key: key);
      _logger.debug(
        "$runtimeType: read '$key' (present: ${value != null})",
      );

      if (value == null) {
        return null;
      }

      if (parser != null) {
        return parser(value);
      }

      // 2. Auto-parse primitives to prevent TypeError crashes
      final String typeStr = T.toString();

      if (typeStr == 'String' || typeStr == 'String?') {
        return value as T?;
      } else if (typeStr == 'int' || typeStr == 'int?') {
        return int.tryParse(value) as T?;
      } else if (typeStr == 'double' || typeStr == 'double?') {
        return double.tryParse(value) as T?;
      } else if (typeStr == 'bool' || typeStr == 'bool?') {
        return (value.toLowerCase() == 'true') as T?;
      }

      return value as T?;
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: get error for key "$key"', e, st);
      await _monitoring.captureException(
        e,
        stackTrace: st,
        context: 'SecureCache',
        level: SeverityLevel.error,
        extras: {'key': key, 'operation': 'read', 'type': T.toString()},
      );
      return null;
    }
  }

  @override
  Future<void> save({required String key, required dynamic value}) async {
    // 3. Automatically stringify primitives so we don't reject valid secure data like PINs
    final dynamic stringValue =
        (value is int || value is double || value is bool)
        ? value.toString()
        : value;

    if (stringValue is! String) {
      _logger.error(
        '$runtimeType: only String/primitives are supported. '
        'Got ${value.runtimeType} for key "$key".',
      );
      return;
    }

    try {
      await _storage.write(key: key, value: stringValue);
      _logger.debug("$runtimeType: saved '$key'");
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: save error for key "$key"', e, st);
      await _monitoring.captureException(
        e,
        stackTrace: st,
        context: 'SecureCache',
        level: SeverityLevel.error,
        extras: {'key': key, 'operation': 'write'},
      );
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: key);
      _logger.debug("$runtimeType: removed '$key'");
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: remove error for key "$key"', e, st);
      await _monitoring.addBreadcrumb(
        message: 'Secure cache remove failed for key "$key"',
        category: 'secure_cache',
        data: {'error': e.toString()},
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.deleteAll();
      _logger.debug('$runtimeType: cleared all entries');
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: clear error', e, st);
      await _monitoring.addBreadcrumb(
        message: 'Secure cache clear failed',
        category: 'secure_cache',
        data: {'error': e.toString()},
      );
    }
  }
}
