# Android Configuration for Mapbox

## Overview

This document provides step-by-step instructions for configuring Mapbox Maps SDK in the Android part of the Flutter application.

## Prerequisites

- Mapbox access token (from Task 2 setup)
- Android Studio or VS Code with Flutter extension
- Flutter project with Android target

## Configuration Steps

### 1. Add Mapbox Repository

Add the Mapbox repository to your Android project's `build.gradle` file.

**File: `android/build.gradle`**

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        // Add Mapbox repository
        maven {
            url 'https://api.mapbox.com/downloads/v2/releases/maven'
            authentication {
                basic(BasicAuthentication)
            }
            credentials {
                // Do not change the username below.
                // This should always be `mapbox` (not your username).
                username = "mapbox"
                // Use the secret token you stored in gradle.properties as the password
                password = project.properties['MAPBOX_DOWNLOADS_TOKEN'] ?: ""
            }
        }
    }
}
```

### 2. Configure Gradle Properties

Add your Mapbox downloads token to the gradle properties file.

**File: `android/gradle.properties`**

```properties
# Mapbox Downloads Token (Secret Token)
MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token_here

# Mapbox Access Token (Public Token)
MAPBOX_ACCESS_TOKEN=pk.your_public_token_here
```

**Important:** Never commit the `gradle.properties` file with actual tokens to version control.

### 3. Update Android Manifest

Configure permissions and metadata in the Android manifest.

**File: `android/app/src/main/AndroidManifest.xml`**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.loagmacrm">

    <!-- Mapbox permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Background location permission for live tracking -->
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Wake lock for background tracking -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:label="LoagmaCRM"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Mapbox access token -->
        <meta-data
            android:name="MAPBOX_ACCESS_TOKEN"
            android:value="${MAPBOX_ACCESS_TOKEN}" />
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <!-- Standard App Intent Filter -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 4. Configure Proguard (for Release Builds)

Add Mapbox-specific Proguard rules to prevent code obfuscation issues.

**File: `android/app/proguard-rules.pro`**

```proguard
# Mapbox ProGuard configuration
-keep class com.mapbox.** { *; }
-keep interface com.mapbox.** { *; }
-keep class com.almeros.android.multitouch.** { *; }
-dontwarn com.mapbox.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Mapbox annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Keep Mapbox model classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
```

### 5. Update App-level Build Gradle

Configure the app-level build.gradle file.

**File: `android/app/build.gradle`**

```gradle
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.loagmacrm"
        minSdkVersion 21  // Mapbox requires minimum API 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // Mapbox configuration
        manifestPlaceholders = [
            MAPBOX_ACCESS_TOKEN: project.properties['MAPBOX_ACCESS_TOKEN'] ?: ""
        ]
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            minifyEnabled false
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
}
```

### 6. Location Permission Handling

Create a custom permission handler for location services.

**File: `android/app/src/main/kotlin/com/example/loagmacrm/LocationPermissionHandler.kt`**

```kotlin
package com.example.loagmacrm

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class LocationPermissionHandler(private val activity: Activity) {
    
    companion object {
        const val LOCATION_PERMISSION_REQUEST_CODE = 1001
        const val BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE = 1002
    }
    
    fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    fun hasBackgroundLocationPermission(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Background location is automatically granted on older versions
        }
    }
    
    fun requestLocationPermission() {
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }
    
    fun requestBackgroundLocationPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE
            )
        }
    }
}
```

### 7. Testing Configuration

Create a test configuration to verify Mapbox setup.

**File: `android/app/src/androidTest/java/com/example/loagmacrm/MapboxConfigTest.java`**

```java
package com.example.loagmacrm;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;

import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class MapboxConfigTest {
    
    @Test
    public void testMapboxTokenConfigured() {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        
        try {
            ApplicationInfo ai = appContext.getPackageManager()
                .getApplicationInfo(appContext.getPackageName(), PackageManager.GET_META_DATA);
            Bundle bundle = ai.metaData;
            
            String mapboxToken = bundle.getString("MAPBOX_ACCESS_TOKEN");
            assertNotNull("Mapbox access token should be configured", mapboxToken);
            assertFalse("Mapbox access token should not be empty", mapboxToken.isEmpty());
            assertTrue("Mapbox access token should start with 'pk.'", mapboxToken.startsWith("pk."));
            
        } catch (PackageManager.NameNotFoundException e) {
            fail("Could not retrieve application info");
        }
    }
    
    @Test
    public void testLocationPermissionsDeclared() {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        
        try {
            String[] permissions = appContext.getPackageManager()
                .getPackageInfo(appContext.getPackageName(), PackageManager.GET_PERMISSIONS)
                .requestedPermissions;
            
            boolean hasFineLocation = false;
            boolean hasCoarseLocation = false;
            
            for (String permission : permissions) {
                if (permission.equals("android.permission.ACCESS_FINE_LOCATION")) {
                    hasFineLocation = true;
                }
                if (permission.equals("android.permission.ACCESS_COARSE_LOCATION")) {
                    hasCoarseLocation = true;
                }
            }
            
            assertTrue("ACCESS_FINE_LOCATION permission should be declared", hasFineLocation);
            assertTrue("ACCESS_COARSE_LOCATION permission should be declared", hasCoarseLocation);
            
        } catch (PackageManager.NameNotFoundException e) {
            fail("Could not retrieve package info");
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **Build Errors**
   - Verify Mapbox repository is correctly added
   - Check that downloads token is valid
   - Ensure minimum SDK version is 21 or higher

2. **Permission Issues**
   - Verify location permissions are declared in manifest
   - Test permission handling on different Android versions
   - Check background location permission for Android 10+

3. **Token Issues**
   - Verify access token is correctly configured
   - Check token format (should start with 'pk.')
   - Ensure token has required scopes

### Testing Commands

```bash
# Build Android app
flutter build apk --debug

# Run on Android device
flutter run -d android

# Run Android tests
cd android && ./gradlew test

# Check permissions
adb shell dumpsys package com.example.loagmacrm | grep permission
```

## Next Steps

After completing Android configuration:
1. Configure iOS settings (see `ios_configuration.md`)
2. Test Mapbox integration in Flutter app
3. Implement map service class
4. Add location tracking functionality