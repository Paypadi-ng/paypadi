import 'package:paypadi/core/services/monitoring/monitoring_config.dart';
import 'package:paypadi/firebase_options_prod.dart';
import 'package:paypadi/main.dart';

void main() async {
  await initializeApp(
    enableMonitoring: true,
    monitoringConfig: MonitoringConfig.prod,
    firebaseConfig: DefaultFirebaseOptions.currentPlatform,
  );
}
