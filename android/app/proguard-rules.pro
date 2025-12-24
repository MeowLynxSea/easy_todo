# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep classes that might be accessed via reflection
-keep class * implements com.fasterxml.jackson.** { *; }
-keep class * implements com.google.gson.** { *; }
-keep class * implements com.google.protobuf.** { *; }

# Keep Flutter specific classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Keep your model classes
-keep class **.model.** { *; }
-keep class **.entity.** { *; }
-keep class **.data.** { *; }

# Keep serialization classes
-keep class **.serializable.** { *; }
-keep class **.generator.** { *; }

# Keep provider classes
-keep class **.provider.** { *; }
-keep class **.notifier.** { *; }

# Keep Hive classes and adapters
-keep class **.HiveService { *; }
-keep class **.adapters.** { *; }
-keep class **.RepeatTypeAdapter { *; }
-keep class **.TimeOfDayAdapter { *; }

# Keep Hive generated classes
-keep class **.*_adapter { *; }
-keep class **.*_g { *; }

# Keep Hive model classes with their fields
-keep @io.hive_flutter.HiveType class * {
    @io.hive_flutter.HiveField *;
}
-keepclassmembers class * {
    @io.hive_flutter.HiveField *;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Ignore warnings
-dontwarn io.flutter.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**