plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    id("kotlin-android")

    // Flutter
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.example.deepshield"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion

    compileOptions {

        sourceCompatibility = JavaVersion.VERSION_17

        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {

        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {

        applicationId = "com.example.deepshield"

        // ✅ REQUIRED FOR ML KIT
        minSdk = 26

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode

        versionName = flutter.versionName
    }

    buildTypes {

        release {

            // Using debug signing temporarily
            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

flutter {

    source = "../.."
}
