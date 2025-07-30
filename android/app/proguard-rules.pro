# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# OneSignal rules
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Agora rules
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Supabase/HTTP rules
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Preserve line numbers for debugging stack traces
-keepattributes LineNumberTable,SourceFile
-renamesourcefileattribute SourceFile

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom model classes
-keep class com.uwaniumnya.crystal.** { *; }

# Keep Dart/Flutter generated classes
-keep class androidx.lifecycle.DefaultLifecycleObserver
