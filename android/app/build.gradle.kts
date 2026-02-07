import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.je_dag_in_beeld.caregiver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.je_dag_in_beeld.caregiver"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Load keystore properties from key.properties file
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Ensure debug builds don't have resource shrinking enabled
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            // Use release signing config if keystore exists, otherwise fall back to debug
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing if keystore not configured
                signingConfig = signingConfigs.getByName("debug")
            }
            // Workaround: SYMBOL_TABLE avoids "failed to strip debug symbols from native libraries" on AAB build.
            // FULL can cause strip to fail on some Flutter/NDK setups; SYMBOL_TABLE still gives Play Console symbolication.
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            // Enable code shrinking and obfuscation for production
            // Note: Set isMinifyEnabled = true if you want to enable ProGuard
            isMinifyEnabled = false
            isShrinkResources = false
            // Only include ProGuard files if minification is enabled
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}
