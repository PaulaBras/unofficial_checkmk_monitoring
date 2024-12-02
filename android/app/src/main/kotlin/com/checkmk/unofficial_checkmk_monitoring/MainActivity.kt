package com.checkmk.unofficial_checkmk_monitoring

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin

class MainActivity: FlutterActivity() {
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001
    private val NOTIFICATION_CHANNEL = "checkmk/ptp_4_monitoring_app"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register all plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Explicitly register the FlutterLocalNotificationsPlugin
        flutterEngine.plugins.add(FlutterLocalNotificationsPlugin())

        // Set up method channel
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            NOTIFICATION_CHANNEL
        )
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    requestNotificationPermission(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        // For Android 13 (API level 33) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this, 
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                // Request the permission
                ActivityCompat.requestPermissions(
                    this, 
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS), 
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
                result.success(false)
            } else {
                result.success(true)
            }
        } else {
            // For older Android versions, notifications are automatically granted
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, 
        permissions: Array<out String>, 
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            // Check if the permission was granted
            val permissionGranted = grantResults.isNotEmpty() && 
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            // Send result back through the method channel
            methodChannel.invokeMethod(
                "notificationPermissionResult", 
                permissionGranted
            )
        }
    }
}
