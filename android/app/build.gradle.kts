plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Forge is Android-first. The minimum SDK uses Flutter's supported default.
val minimumSdk = flutter.minSdkVersion

android {
    namespace = "com.forge.forge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Flutter's supported minimum: API 24 (Android 7.0+).
        minSdk = minimumSdk
        // Targets the latest stable SDK supported by this Flutter release.
        targetSdk = flutter.targetSdkVersion
        applicationId = "com.forge.forge"
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signed with the debug key until a production keystore is added.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Name the built artifact forge.apk instead of app.apk.
base {
    archivesName = "forge"
}

flutter {
    source = "../.."
}
