fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android deploy_firebase

```sh
[bundle exec] fastlane android deploy_firebase
```

Dev: distribute the dev APK via Firebase App Distribution

Env: FIREBASE_APP_ID, FIREBASE_GROUPS, RELEASE_NOTES

### android deploy_staging

```sh
[bundle exec] fastlane android deploy_staging
```

Staging: upload the staging app to the Play Store internal testing track

### android deploy_prod

```sh
[bundle exec] fastlane android deploy_prod
```

Prod: release to the Play Store production track as a staged rollout

Env: PLAY_ROLLOUT (fraction of users, default 0.1)

----


## iOS

### ios sync_dev_certs

```sh
[bundle exec] fastlane ios sync_dev_certs
```

Dev: sync development certificates and profiles

### ios sync_appstore_certs

```sh
[bundle exec] fastlane ios sync_appstore_certs
```

Staging/Prod: sync App Store certificates and profiles

Options: flavor (staging | prod)

### ios deploy_firebase

```sh
[bundle exec] fastlane ios deploy_firebase
```

Dev: distribute the dev IPA via Firebase App Distribution

Env: FIREBASE_APP_ID, FIREBASE_GROUPS, RELEASE_NOTES

### ios deploy_staging

```sh
[bundle exec] fastlane ios deploy_staging
```

Staging: upload the staging app to TestFlight

### ios deploy_prod

```sh
[bundle exec] fastlane ios deploy_prod
```

Prod: upload to App Store Connect and submit for review

Release stays manual: publish from App Store Connect once Apple approves.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
