import groovy.json.JsonSlurper

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
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
    id("com.android.application") version "9.2.1" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("org.jetbrains.kotlin.android") version "2.3.21" apply false
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

include(":app")

val flutterProjectRoot: File? = rootDir.parentFile
val pluginsFile = File(flutterProjectRoot, ".flutter-plugins-dependencies")

if (pluginsFile.exists()) {
    val json = JsonSlurper().parse(pluginsFile) as Map<*, *>

    val androidPlugins =
        ((json["plugins"] as Map<*, *>)["android"] as List<Map<*, *>>)

    val bridgePlugin = androidPlugins.firstOrNull {
        it["name"] == "anymex_extension_runtime_bridge"
    }

    if (bridgePlugin != null) {
        val bridgeDir = File(bridgePlugin["path"] as String)

        include(":anymex_extension_runtime_bridge")
        project(":anymex_extension_runtime_bridge").projectDir = bridgeDir.resolve("android")
    }
}
