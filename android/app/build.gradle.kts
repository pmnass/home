import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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
        minSdk = 26 // Android 8.0
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    signingConfigs {
        create("release") {
            keyAlias = System.getenv("BITRISEIO_ANDROID_KEYSTORE_ALIAS") ?: keystoreProperties["keyAlias"] as String?
            keyPassword = System.getenv("BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD") ?: keystoreProperties["keyPassword"] as String?
            storeFile = System.getenv("BITRISEIO_ANDROID_KEYSTORE_PATH")?.let { file(it) }
            storePassword = System.getenv("BITRISEIO_ANDROID_KEYSTORE_PASSWORD") ?: keystoreProperties["storePassword"] as String?
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
flutter {
    source = "../.."
}
