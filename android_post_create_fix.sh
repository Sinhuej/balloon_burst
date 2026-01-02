#!/usr/bin/env bash
set -euo pipefail

echo "== Fix regenerated android/app/build.gradle =="

cat > android/app/build.gradle <<'EOG'
plugins {
    id "com.android.application"
    id "org.jetbrains.kotlin.android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.balloon_burst"
    compileSdk 35

    defaultConfig {
        applicationId "com.example.balloon_burst"
        minSdk 21
        targetSdk 35
        versionCode 1
        versionName "1.0"
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source "../.."
}
EOG

# hard guard: fail if Flutter template poison exists
if grep -n "flutter.version" android/app/build.gradle; then
  echo "ERROR: flutter.versionCode still present"
  exit 1
fi

echo "OK: android/app/build.gradle sanitized"
