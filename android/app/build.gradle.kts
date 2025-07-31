import org.gradle.api.JavaVersion
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.uwaniumnya.crystal"  // Updated to match AndroidManifest.xml

    compileSdk = flutter.compileSdkVersion

    ndkVersion = "27.0.12077973"  // <-- BOOM, override here!

    compileOptions {
         sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
    isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
      jvmTarget = "11"

    }

    defaultConfig {
        applicationId = "com.uwaniumnya.crystal"
        minSdk = 23
        targetSdk = 33  // Target Android 13 for Samsung A23 compatibility
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // NDK configuration for Samsung A23 ARM64 compatibility
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
        
        // Manifest placeholders for deep linking/redirect functionality
        manifestPlaceholders["redirectHostName"] = "callback"
        manifestPlaceholders["redirectSchemeName"] = "crystalapp"
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("keyAlias") && 
                keystoreProperties.containsKey("storeFile") &&
                file(keystoreProperties["storeFile"] as String).exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.containsKey("keyAlias") && 
                               keystoreProperties.containsKey("storeFile") &&
                               file(keystoreProperties["storeFile"] as String).exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}



dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:33.16.0"))
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

 implementation("com.onesignal:OneSignal:[5.1.6, 5.1.99]")

  // Spotify SDK is now handled by the spotify-app-remote module

  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}


apply(plugin = "com.google.gms.google-services")
