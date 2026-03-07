# ============================================================
# AnymeX ProGuard/R8 Rules
# ============================================================

-verbose
-optimizationpasses 5
-dontpreverify
-dontnote
-ignorewarnings

# ============================================================
# Flutter
# ============================================================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============================================================
# Your app package
# ============================================================
-keep class com.ryan.anymex.** { *; }
-keepclassmembers class com.ryan.anymex.** { *; }

# ============================================================
# Google Play Core — Flutter references these for deferred
# components but they are absent in sideloaded APKs.
# We keep them to avoid R8 "Missing class" hard errors.
# ============================================================
-keep class com.google.android.play.core.** { *; }

# ============================================================
# Firebase / Gson
# ============================================================
-keep class com.google.gson.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ============================================================
# Kotlin
# ============================================================
-keep class ** implements kotlin.Metadata
-keep class ** extends kotlin.Metadata
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# ============================================================
# Isar (local database)
# ============================================================
-keep class isar.** { *; }

# ============================================================
# Rust Bridge / JNI (flutter_rust_bridge)
# ============================================================
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# ============================================================
# OkHttp / Retrofit / Networking
# ============================================================
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================================
# MPV (libmpv)
# ============================================================
-keep class is.xyz.mpv.** { *; }
-dontwarn is.xyz.mpv.**

# ============================================================
# WebView JavaScript Interface
# ============================================================
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ============================================================
# Keep annotations and signatures (needed for reflection)
# ============================================================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions,InnerClasses

# ============================================================
# Suppress remaining misc warnings
# ============================================================
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
