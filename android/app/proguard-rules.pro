# ============================================================
# AnymeX ProGuard/R8 Rules
# ============================================================

-verbose
-dontpreverify
-dontnote
-ignorewarnings

# Keep annotations, generic signatures, inner classes, line numbers for reflection
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses, RuntimeVisibleAnnotations, AnnotationDefault, SourceFile, LineNumberTable

# Flutter
-keep class io.flutter.embedding.** { *; }
-keep class com.ryan.anymex.MainActivity { *; }

# Google Play Core
-keep class com.google.android.play.core.** { *; }

# Firebase / Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Extension Frameworks & Dynamic Loading Entrypoints (prevent R8 stripping dynamic extension classes)
-keep class com.ryan.runtimebridge.** { *; }
-keep class com.anymex.runtimehost.** { *; }
-keep class com.lagradost.cloudstream3.** { *; }
-keep interface com.lagradost.cloudstream3.** { *; }
-keepclassmembers class com.lagradost.cloudstream3.** { *; }
-keep class eu.kanade.tachiyomi.** { *; }
-keep interface eu.kanade.tachiyomi.** { *; }

# AndroidX components used by extension bridge
-keep class androidx.appcompat.** { *; }
-keep interface androidx.appcompat.** { *; }
-keep class com.google.android.material.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.preference.** { *; }
-keep interface androidx.preference.** { *; }
-keep class androidx.fragment.** { *; }
-keep class androidx.core.** { *; }

# Kotlin Runtime & Serialization
-keep class ** implements kotlin.Metadata
-keep class ** extends kotlin.Metadata
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-keep,allowoptimization class kotlin.** { public protected *; }
-keep,allowoptimization class kotlinx.coroutines.** { public protected *; }
-keep,allowoptimization class kotlinx.serialization.** { public protected *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# Isar (local database)
-keep class isar.** { *; }

# Rust Bridge / JNI
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Networking Libraries
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# MPV (libmpv)
-keep class is.xyz.mpv.** { *; }
-dontwarn is.xyz.mpv.**

# Injekt & JS Engines
-keep,allowoptimization class uy.kohesive.injekt.** { public protected *; }
-keep class app.cash.quickjs.** { *; }
-keep class org.mozilla.** { *; }
-dontwarn org.mozilla.**
-keep class org.schabi.newpipe.** { *; }

# HTML & String Utilities
-keep class org.jsoup.** { *; }
-keepclassmembers class org.jsoup.nodes.Document { *; }
-keep class me.xdrop.fuzzywuzzy.** { *; }

# RxJava
-keep class rx.** { *; }
-keep class io.reactivex.** { *; }
-dontwarn rx.**

# WebView JavaScript Interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Suppress remaining misc warnings
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
