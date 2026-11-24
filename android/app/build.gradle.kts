import com.android.build.api.dsl.ApplicationExtension

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

extensions.configure<ApplicationExtension> {
    namespace = "com.qaxercrash.fiona"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.qaxercrash.fiona"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
