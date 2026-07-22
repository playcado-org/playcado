# Flutter plugin system needs reflection access for method channels
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep generic signature attributes for reflection-based serialization
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
