# Flutter & Google ML Kit Text Recognition Proguard Rules
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Flutter deferred components (Play Store Split) suppression
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep ML Kit components
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }

# Flutter & Plugins standard keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods for JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Play Services Auth & Sign-In Keep Rules (Critical for Release APK)
-keep class com.google.android.gms.auth.api.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.internal.auth.** { *; }
-dontwarn com.google.android.gms.**

