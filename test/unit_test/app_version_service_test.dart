import 'package:flutter_test/flutter_test.dart';
import 'package:paypadi/core/services/app_version_service.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';

class _RecordingMonitoring implements MonitoringService {
  final List<String> breadcrumbs = [];

  @override
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) async => breadcrumbs.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back to placeholder info and leaves a breadcrumb when the '
      'platform cannot report the version', () async {
    // No package_info_plus platform implementation is registered in tests,
    // so reading the app info fails here.
    final monitoring = _RecordingMonitoring();
    final service = AppVersionService(monitoring: monitoring);

    final info = await service.getAppInformation();

    expect(info.version, '0.0.0');
    expect(info.buildNumber, '0');
    expect(monitoring.breadcrumbs, ['Failed to retrieve PackageInfo']);
  });
}
