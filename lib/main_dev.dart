import 'package:paypadi/core/services/monitoring/monitoring_config.dart';
import 'package:paypadi/firebase_options_dev.dart';
import 'package:paypadi/main.dart';

void main() async {
  await initializeApp(
    enableMonitoring: false,
    monitoringConfig: MonitoringConfig.dev,
    firebaseConfig: DefaultFirebaseOptions.currentPlatform,
  );
}
