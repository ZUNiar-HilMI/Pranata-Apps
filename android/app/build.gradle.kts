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
    namespace = "com.example.my_first_app"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.my_first_app"
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

    applicationVariants.all {
        val variant = this
        variant.outputs.forEach { output ->
            val apkOutput = output as? com.android.build.gradle.internal.api.ApkVariantOutputImpl
            if (apkOutput != null) {
                apkOutput.outputFileName = "PRANATA-${variant.name}.apk"
            }
        }
    }
}

tasks.register("copyCustomApk") {
    doLast {
        val buildDir = project.layout.buildDirectory.asFile.get()
        val debugApk = file("$buildDir/outputs/apk/debug/PRANATA-debug.apk")
        val releaseApk = file("$buildDir/outputs/apk/release/PRANATA-release.apk")
        
        val flutterApkDir = file("${project.rootDir}/../build/app/outputs/flutter-apk")
        if (!flutterApkDir.exists()) {
            flutterApkDir.mkdirs()
        }
        
        if (debugApk.exists()) {
            debugApk.copyTo(file("$flutterApkDir/PRANATA-debug.apk"), overwrite = true)
            println("👉 Custom debug APK copied to: $flutterApkDir/PRANATA-debug.apk")
        }
        if (releaseApk.exists()) {
            releaseApk.copyTo(file("$flutterApkDir/PRANATA-release.apk"), overwrite = true)
            println("👉 Custom release APK copied to: $flutterApkDir/PRANATA-release.apk")
        }
    }
}

tasks.configureEach {
    if (name.startsWith("assemble")) {
        finalizedBy("copyCustomApk")
    }
}

flutter {
    source = "../.."
}
