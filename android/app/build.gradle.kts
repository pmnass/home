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

    // ✅ Signing configuration (Kotlin DSL style)
    signingConfigs {
        create("release") {
            storeFile = file("${System.getenv("HOME")}/keystores/my-release-key.jks")
            storePassword = System.getenv("821253")
            keyAlias = System.getenv("my-key-alias")
            keyPassword = System.getenv("821253")
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            // Debug builds remain unsigned
        }
    }
}

flutter {
    source = "../.."
}
