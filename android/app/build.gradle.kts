import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadKeyProperties(fileName: String): Properties? {
    val file = rootProject.file(fileName)

    if (!file.exists()) {
        return null
    }

    return Properties().apply {
        load(FileInputStream(file))
    }
}

val devKeyProperties =
    loadKeyProperties("key-dev.properties")
        ?: loadKeyProperties("key.properties")

val stagingKeyProperties =
    loadKeyProperties("key-staging.properties")
        ?: loadKeyProperties("key.properties")

val prodKeyProperties =
    loadKeyProperties("key-prod.properties")
        ?: loadKeyProperties("key.properties")

android {
    namespace = "com.paypadi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.paypadi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {

        create("devUpload") {
            devKeyProperties?.let {
                keyAlias = it["keyAlias"] as String?
                keyPassword = it["keyPassword"] as String?
                storePassword = it["storePassword"] as String?
                storeFile =
                    (it["storeFile"] as String?)
                        ?.let(::file)
            }
        }

        create("stagingUpload") {
            stagingKeyProperties?.let {
                keyAlias = it["keyAlias"] as String?
                keyPassword = it["keyPassword"] as String?
                storePassword = it["storePassword"] as String?
                storeFile =
                    (it["storeFile"] as String?)
                        ?.let(::file)
            }
        }

        create("prodUpload") {
            prodKeyProperties?.let {
                keyAlias = it["keyAlias"] as String?
                keyPassword = it["keyPassword"] as String?
                storePassword = it["storePassword"] as String?
                storeFile =
                    (it["storeFile"] as String?)
                        ?.let(::file)
            }
        }
    }

    buildTypes {

        getByName("debug") {
            signingConfig =
                if (devKeyProperties != null)
                    signingConfigs.getByName("devUpload")
                else null
        }

        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt",
                ),
                "proguard-rules.pro",
            )
        }
    }

    flavorDimensions += "flavor-type"

    productFlavors {

        create("dev") {
            dimension = "flavor-type"

            applicationIdSuffix = ".dev"

            resValue(
                "string",
                "app_name",
                "Paypadi dev",
            )

            signingConfig =
                if (devKeyProperties != null)
                    signingConfigs.getByName("devUpload")
                else null
        }

        create("staging") {
            dimension = "flavor-type"

            applicationIdSuffix = ".staging"

            resValue(
                "string",
                "app_name",
                "Paypadi staging",
            )

            signingConfig =
                if (stagingKeyProperties != null)
                    signingConfigs.getByName("stagingUpload")
                else null
        }

        create("prod") {
            dimension = "flavor-type"

            resValue(
                "string",
                "app_name",
                "Paypadi",
            )

            signingConfig =
                if (prodKeyProperties != null)
                    signingConfigs.getByName("prodUpload")
                else null
        }
    }
}

flutter {
    source = "../.."
}
