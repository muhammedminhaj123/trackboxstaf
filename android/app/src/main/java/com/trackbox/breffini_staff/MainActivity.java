package com.trackbox.breffini_staff;

import static androidx.activity.result.ActivityResultCallerKt.registerForActivityResult;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.Objects;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
// import android.os.Bundle; // Import for Bundle
// import android.view.WindowManager;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "methodChannel";
    private MethodChannel.Result pendingResult;
    private static final int FULL_SCREEN_INTENT_REQUEST_CODE = 1001;


     @Override
     protected void onCreate(Bundle savedInstanceState) {
         super.onCreate(savedInstanceState);

//         // Set the FLAG_SECURE to prevent screenshots and screen recordings
//         getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE,
//                 WindowManager.LayoutParams.FLAG_SECURE);
         new MethodChannel(Objects.requireNonNull(getFlutterEngine()).getDartExecutor().getBinaryMessenger(), CHANNEL)
                 .setMethodCallHandler(
                         new MethodChannel.MethodCallHandler() {
                             @Override
                             public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
                                 if (call.method.equals("requestBatteryOptimization")) {
                                     pendingResult = result;
                                     requestBatteryOptimization();

                                 } else if (call.method.equals("requestFullScreenIntentPermission")) {
                                     if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                         pendingResult = result;
                                         requestFullScreenIntentPermission();
                                     } else {
                                         result.success(true);


                                     }

                                 } else {
                                     result.notImplemented();
                                 }
                             }
                         }
                 );

     }
    private boolean isFullScreenIntentAllowed() {
        // Pre-Android 10, full-screen intents are always allowed
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return true;
        }

        // For Android 10 and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                NotificationManager notificationManager =
                        (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

                // Check if the app is allowed to use full-screen intents
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    return notificationManager.canUseFullScreenIntent();
                }
            } catch (Exception e) {
                return false;
            }
        }

        return false;
    }
    /**
     * Requests permission for full-screen intents
     */
    @RequiresApi(api = Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private void requestFullScreenIntentPermission() {
        // Only relevant for Android 10 and above
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            pendingResult.success(true);

            return;
        }

        if (!isFullScreenIntentAllowed()) {
            Intent intent = new Intent(
                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                    Uri.parse("package:" + getPackageName())
            );
            startActivityForResult(intent,FULL_SCREEN_INTENT_REQUEST_CODE);

//            startActivityForResult(intent, FULL_SCREEN_INTENT_REQUEST_CODE);
        }else{
            pendingResult.success(true);

        }
    }
    private void requestBatteryOptimization() {
        if(isBatteryOptimizationEnabled()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                String packageName = getPackageName();
                PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);

                if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                    try {
                        Intent intent = new Intent();
                        intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                        intent.setData(Uri.parse("package:" + packageName));
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivity(intent);
                        pendingResult.success(true);

                    } catch (Exception e) {
                        e.printStackTrace();
                        pendingResult.success(false);
                    }
                }else{
                    pendingResult.success(true);

                }
            }else{
                pendingResult.success(true);

            }
        }else{
            pendingResult.success(true);

        }
    }

    private boolean isBatteryOptimizationEnabled() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            String packageName = getPackageName();
            PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
            boolean ss=!pm.isIgnoringBatteryOptimizations(packageName);
            return ss;
        }
        return false;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FULL_SCREEN_INTENT_REQUEST_CODE) {
            if (pendingResult != null) {
                pendingResult.success(isFullScreenIntentAllowed());
                pendingResult = null;
            }
        }
    }
}
