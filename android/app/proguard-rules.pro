# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# advanced_root_detection — keep plugin + NDK bridge from stripping
-keep class com.advanced_root_detection.** { *; }
-keep class **.AdvanceRootDetectionPlugin { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# JNI / native shield library
-keepclasseswithmembernames class * {
    native <methods>;
}

# Exam VPN lockdown
-keep class com.example.military_exam.LocalVpnService { *; }
-keep class com.example.military_exam.MainActivity { *; }

# Optional Play Core references from Flutter engine (deferred components)
-dontwarn com.google.android.play.core.**
