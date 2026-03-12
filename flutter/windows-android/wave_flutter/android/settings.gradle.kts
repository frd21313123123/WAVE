pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        require(localPropertiesFile.exists()) { "local.properties not found. Set flutter.sdk there." }
        localPropertiesFile.inputStream().use { properties.load(it) }
        val sdk = properties.getProperty("flutter.sdk")
        require(!sdk.isNullOrBlank()) { "flutter.sdk not set in local.properties" }
        sdk
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.10.0" apply false
}

include(":app")
