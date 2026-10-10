import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties (git-ignored, never committed).
// Without it (e.g. in CI) release builds fall back to the debug key.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.patelkeyur.navmaas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs java.time on older Android.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.patelkeyur.navmaas"
        // Android 8: Health Connect (walk steps) needs it.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    // `flutter build apk --target-platform android-arm,android-arm64` (the
    // phone build, ~64 MB) still gets one plugin's x86_64 library; drop
    // every ABI that wasn't asked for, so the APK never claims an ABI it
    // can't run. The universal build (no --target-platform) keeps them all.
    val requestedAbis = (project.findProperty("target-platform") as String?)
        ?.split(",")
        ?.map {
            mapOf(
                "android-arm" to "armeabi-v7a",
                "android-arm64" to "arm64-v8a",
                "android-x64" to "x86_64",
                "android-x86" to "x86",
            )[it.trim()]
        }
    if (requestedAbis != null) {
        packaging {
            jniLibs {
                for (abi in listOf("armeabi-v7a", "arm64-v8a", "x86_64", "x86")) {
                    if (abi !in requestedAbis) excludes += "lib/$abi/**"
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
        // Navmaas and Nourishly both declare the NOURISHLY_SHARE signature
        // permission (M8b). Android refuses to install an app that declares
        // it again under another key, so a debug build uses the owner's key
        // when it's here, and installs beside her Nourishly.
        debug {
            signingConfigs.findByName("release")?.let { signingConfig = it }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // App-limit check (M11a, ADR 050); the same version home_widget brings.
    implementation("androidx.work:work-runtime-ktx:2.11.2")
}
