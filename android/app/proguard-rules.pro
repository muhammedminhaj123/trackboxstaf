-keep class **.zego.**  { *; }
-keep class **.**.zego_zpns.** { *; }
-keep class **.**.zego_zim.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keep class com.google.common.reflect.TypeToken
-keep class * extends com.google.common.reflect.TypeToken



# Preserve TypeToken generic types
-keepattributes Signature
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
# Preserve serialized fields for Gson
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken { *; }


# Suppress warnings for various push notification libraries
-dontwarn com.heytap.msp.push.HeytapPushManager
-dontwarn com.heytap.msp.push.callback.ICallBackResultService
-dontwarn com.heytap.msp.push.mode.DataMessage
-dontwarn com.heytap.msp.push.service.DataMessageCallbackService
-dontwarn com.huawei.hms.aaid.HmsInstanceId
-dontwarn com.huawei.hms.common.ApiException
-dontwarn com.huawei.hms.push.HmsMessageService
-dontwarn com.huawei.hms.push.RemoteMessage$Notification
-dontwarn com.huawei.hms.push.RemoteMessage
-dontwarn com.vivo.push.IPushActionListener
-dontwarn com.vivo.push.PushClient
-dontwarn com.vivo.push.PushConfig$Builder
-dontwarn com.vivo.push.PushConfig
-dontwarn com.vivo.push.listener.IPushQueryActionListener
-dontwarn com.vivo.push.model.UPSNotificationMessage
-dontwarn com.vivo.push.model.UnvarnishedMessage
-dontwarn com.vivo.push.sdk.OpenClientPushMessageReceiver
-dontwarn com.vivo.push.util.VivoPushException
-dontwarn com.xiaomi.mipush.sdk.MiPushClient
-dontwarn com.xiaomi.mipush.sdk.MiPushCommandMessage
-dontwarn com.xiaomi.mipush.sdk.MiPushMessage
-dontwarn com.xiaomi.mipush.sdk.PushMessageReceiver
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.OpenSSLProvider
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry

# Video Player Rules
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Push Notification Rules
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.android.gms.** { *; }

-keep class com.google.firebase.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

