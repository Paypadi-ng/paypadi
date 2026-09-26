// PLACEHOLDER — replace this file by running the FlutterFire CLI once the
// staging Firebase apps (Android com.paypadi.staging, iOS com.paypadi.staging)
// exist:
//
//   flutterfire configure \
//     --out=lib/firebase_options_staging.dart \
//     --android-package-name=com.paypadi.staging \
//     --ios-bundle-id=com.paypadi.staging
//
// Until then the staging app fails fast at startup instead of silently
// talking to the prod Firebase project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured for the staging flavor yet. '
      'See lib/firebase_options_staging.dart.',
    );
  }
}
