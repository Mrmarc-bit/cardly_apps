# Flutter & Google ML Kit Text Recognition Proguard Rules
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit components
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
