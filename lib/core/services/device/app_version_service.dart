import 'package:package_info_plus/package_info_plus.dart';
import 'package:paypadi/core/services/monitoring/monitoring_service.dart';

class AppVersionService {
  AppVersionService({required MonitoringService monitoring})
    : _monitoring = monitoring;

  final MonitoringService _monitoring;

  Future<PackageInfo> getAppInformation() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      // Non-fatal — log as breadcrumb, not a full exception capture
      await _monitoring.addBreadcrumb(
        message: 'Failed to retrieve PackageInfo',
        category: 'app.version',
        data: {'error': e.toString()},
      );
      return PackageInfo(
        appName: 'Unknown',
        packageName: 'Unknown',
        version: '0.0.0',
        buildNumber: '0',
      );
    }
  }
}
