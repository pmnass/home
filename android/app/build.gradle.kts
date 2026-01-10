plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.darvin_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.darvin_app"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Signing configuration
    signingConfigs {
        release {
            storeFile file("C:/Users/DELL/Downloads/new/my-release-key.jks")
            storePassword "821253"       // your keystore password
            keyAlias "my-key-alias"        // confirmed alias
            keyPassword "821253"         // your key password
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // Debug builds remain unsigned
        }
    }
}

flutter {
    source = "../.."
}
