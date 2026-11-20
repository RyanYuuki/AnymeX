import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://jitpack.io")
        maven("https://storage.googleapis.com/download.flutter.io")
    }
}

rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    afterEvaluate {
        extensions.findByType(BaseExtension::class.java)?.apply {
            if (project.name == "permission_handler_android") {
                compileSdkVersion("android-37")
            } else {
                compileSdkVersion(36)
            }
            buildToolsVersion("36.0.0")

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }

            if (namespace == null) {
                namespace = project.group.toString()
            }
        }

        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
        }

        tasks.matching { it.name.startsWith("lint") }.configureEach {
            enabled = false
        }

        tasks.matching { it.name.startsWith("uploadCrashlyticsMappingFile") }.configureEach {
            enabled = false
        }

        tasks.matching { it.name.startsWith("extract") && it.name.endsWith("Annotations") }.configureEach {
            actions.clear()
            doLast {
                outputs.files.forEach { f ->
                    if (f.extension.isNotEmpty()) {
                        f.parentFile.mkdirs()
                        if (!f.exists()) f.createNewFile()
                    } else {
                        f.mkdirs()
                    }
                }
            }
        }

        tasks.matching { project.name == "app" && it.name.endsWith("AarMetadata") }.configureEach {
            enabled = false
        }
    }

    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }

    configurations.all {
        resolutionStrategy {
            force("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.11.0")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.11.0")
            force("com.google.code.gson:gson:2.11.0")
        }
    }

    layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(name)
    )
}

subprojects {
    evaluationDependsOn(":app")
}

configurations.all {
    resolutionStrategy {
        force("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0")
        force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
        force("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.11.0")
        force("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.11.0")
        force("com.google.code.gson:gson:2.11.0")
    }
    resolutionStrategy.eachDependency {
        if (requested.group == "io.flutter" && requested.name.contains("flutter_embedding")) {
            useVersion("1.0.0-ef0cd000916d64fa0c5d09cc809fa7ad244a5767")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
