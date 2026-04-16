plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

android {
    namespace = "com.example.remindly"
    compileSdk = 33

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = '11'
    }

    defaultConfig {
        applicationId = "com.example.remindly"
        minSdk = flutter.minSdkVersion
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.2.1'
    implementation 'com.google.firebase:firebase-analytics:21.2.2'
}
