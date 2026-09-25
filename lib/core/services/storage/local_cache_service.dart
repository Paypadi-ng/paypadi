import 'dart:convert' show json;

import 'package:paypadi/core/services/monitoring/monitoring_service.dart';
import 'package:paypadi/core/services/storage/cache_service.dart';
import 'package:paypadi/core/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart' show Talker;

/// [CacheService] backed by [SharedPreferencesWithCache].
///
/// Supports all primitive Dart types plus JSON-encodable objects/maps.
class LocalCacheService implements CacheService {
  LocalCacheService({
    required SharedPreferencesWithCache sharedPreferences,
    required MonitoringService monitoring,
  }) : _prefs = sharedPreferences,
       _monitoring = monitoring;

  final Talker _logger = debugLogger;
  final MonitoringService _monitoring;
  final SharedPreferencesWithCache _prefs;

  @override
  Future<T?> get<T>(String key, [T Function(dynamic raw)? parser]) async {
    try {
      dynamic raw;
      final String typeStr = T.toString();

      // 1. Safe generic checks that handle both T and T? gracefully
      if (typeStr == 'String' || typeStr == 'String?') {
        raw = _prefs.getString(key);
      } else if (typeStr == 'int' || typeStr == 'int?') {
        raw = _prefs.getInt(key);
      } else if (typeStr == 'double' || typeStr == 'double?') {
        raw = _prefs.getDouble(key);
      } else if (typeStr == 'bool' || typeStr == 'bool?') {
        raw = _prefs.getBool(key);
      } else if (typeStr == 'List<String>' || typeStr == 'List<String>?') {
        raw = _prefs.getStringList(key);
      } else {
        // 2. Map<String, dynamic> and custom objects stored as JSON strings.
        final String? encoded = _prefs.getString(key);
        if (encoded == null || encoded.isEmpty) {
          return null;
        }

        try {
          raw = json.decode(encoded);
          if (typeStr == 'Map<String, dynamic>' ||
              typeStr == 'Map<String, dynamic>?') {
            raw = raw as Map<String, dynamic>;
          }
        } on Exception catch (e, st) {
          _logger.error(
            '$runtimeType: JSON decode failed for key "$key"',
            e,
            st,
          );
          return null;
        }
      }

      if (raw == null) {
        return null;
      }

      return parser != null ? parser(raw) : raw as T?;
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: get error for key "$key"', e, st);
      await _monitoring.addBreadcrumb(
        message: 'Cache read failed for key "$key"',
        category: 'cache',
        data: {'error': e.toString(), 'type': T.toString()},
      );
      return null;
    }
  }

  @override
  Future<void> save({required String key, required dynamic value}) async {
    try {
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(key, value);
      } else {
        // 3. Attempt to JSON encode custom models or Maps safely
        try {
          final String encoded = json.encode(value);
          await _prefs.setString(key, encoded);
        } on Exception catch (_) {
          _logger.error(
            '$runtimeType: unsupported type or failed encode for key "$key": ${value.runtimeType}',
          );
          await _monitoring.addBreadcrumb(
            message: 'Cache write skipped: unsupported type for key "$key"',
            category: 'cache',
            data: {'valueType': value.runtimeType.toString()},
          );
        }
      }
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: save error for key "$key"', e, st);
      await _monitoring.addBreadcrumb(
        message: 'Cache write failed for key "$key"',
        category: 'cache',
        data: {
          'error': e.toString(),
          'valueType': value.runtimeType.toString(),
        },
      );
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
      _logger.debug("$runtimeType: removed '$key'");
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: remove error for key "$key"', e, st);
      await _monitoring.addBreadcrumb(
        message: 'Cache remove failed for key "$key"',
        category: 'cache',
        data: {'error': e.toString()},
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _prefs.clear();
      _logger.debug('$runtimeType: cleared all entries');
    } on Exception catch (e, st) {
      _logger.error('$runtimeType: clear error', e, st);
      await _monitoring.addBreadcrumb(
        message: 'Cache clear failed',
        category: 'cache',
        data: {'error': e.toString()},
      );
    }
  }
}
