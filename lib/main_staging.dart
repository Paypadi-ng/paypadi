import 'package:paypadi/firebase_options_staging.dart';
import 'package:paypadi/main.dart';

void main() async {
  await initializeApp(
    enableMonitoring: true,
    firebaseConfig: DefaultFirebaseOptions.currentPlatform,
  );
}
