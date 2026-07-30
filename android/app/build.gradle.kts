plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cleantracker.clean_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications uses java.time APIs; core library
        // desugaring makes them available on older Android versions.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cleantracker.clean_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// home_widget pulls androidx.glance (Jetpack Compose) transitively, and Glance
// in turn drags in WorkManager, whose androidx.startup InitializationProvider
// runs at app launch — before the first Flutter frame. We only ever use classic
// RemoteViews app widgets (never Glance), so this whole stack is dead weight and
// its startup initializer is the likely cause of an instant on-device launch
// crash. Excluding it keeps the widgets working and slims the APK.
configurations.all {
    exclude(group = "androidx.glance")
    exclude(group = "androidx.work", module = "work-runtime")
    exclude(group = "androidx.work", module = "work-runtime-ktx")
}

dependencies {
    // Required by flutter_local_notifications' use of java.time on older APIs.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
