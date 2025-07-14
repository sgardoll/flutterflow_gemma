# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
-dontwarn org.bouncycastle.jce.provider.BouncyCastleProvider
-dontwarn org.bouncycastle.pqc.jcajce.provider.BouncyCastlePQCProvider
-keep class org.xmlpull.v1.** { *; }




# Rules for MediaPipe and Protobuf
# Keep Protobuf generated classes
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# MediaPipe
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# OkHttp (used by MediaPipe)
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }

# javax.lang.model.*
-keep class javax.lang.model.** { *; }
-dontwarn javax.lang.model.**

# AutoValue / Javapoet if needed
-keep class com.google.auto.value.** { *; }
-dontwarn com.google.auto.value.**
-keep class autovalue.shaded.com.squareup.javapoet.** { *; }
-dontwarn autovalue.shaded.com.squareup.javapoet.**
