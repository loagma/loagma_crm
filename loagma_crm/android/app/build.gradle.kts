import com.android.build.gradle.internal.api.BaseVariantOutputImpl

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.loagma_crm"
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
        applicationId = "com.example.loagma_crm"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Mapbox configuration - inject access token into manifest
        manifestPlaceholders["MAPBOX_ACCESS_TOKEN"] = project.findProperty("MAPBOX_ACCESS_TOKEN") as String? ?: ""
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // APK rename (optional but valid)
    applicationVariants.all {
        outputs.forEach { output ->
            val appName = "loagmaCRM"
            val buildType = buildType.name
            val versionName = versionName ?: "1.0"

            val apkName = "$appName-$buildType-v$versionName.apk"
            (output as BaseVariantOutputImpl).outputFileName = apkName
        }
    }
}

flutter {
    source = "../.."
}
