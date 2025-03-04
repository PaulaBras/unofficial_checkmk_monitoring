package com.checkmk.unofficial_checkmk_monitoring

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001
    private val BATTERY_OPTIMIZATION_REQUEST_CODE = 1002
    private val NOTIFICATION_CHANNEL = "checkmk/ptp_4_monitoring_app"
    private val WIDGET_CHANNEL = "checkmk/dashboard_widget"
    private lateinit var methodChannel: MethodChannel
    private lateinit var widgetChannel: MethodChannel
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if we were launched from the widget with a refresh request
        if (intent?.getBooleanExtra("refresh_widget", false) == true) {
            // We'll handle this in configureFlutterEngine
            intent.removeExtra("refresh_widget")
        }
    }

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
                "isBatteryOptimizationDisabled" -> {
                    result.success(isBatteryOptimizationDisabled())
                }
                "requestDisableBatteryOptimization" -> {
                    requestDisableBatteryOptimization(result)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings(result)
                }
                "getBatteryLevel" -> {
                    result.success(getBatteryLevel())
                }
                else -> result.notImplemented()
            }
        }
        
        // Set up widget method channel
        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, 
            WIDGET_CHANNEL
        )
        
        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateDashboardWidget" -> {
                    try {
                        val hostsData = call.argument<String>("hostsData")
                        val servicesData = call.argument<String>("servicesData")
                        
                        if (hostsData != null && servicesData != null) {
                            updateDashboardWidget(hostsData, servicesData)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                        }
                    } catch (e: Exception) {
                        result.error("UPDATE_FAILED", "Failed to update widget: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Check if we were launched from the widget with a refresh request
        if (intent?.getBooleanExtra("refresh_widget", false) == true) {
            // Trigger a refresh of the dashboard data
            Handler(Looper.getMainLooper()).postDelayed({
                widgetChannel.invokeMethod("refreshWidgetData", null)
            }, 1000) // Delay to ensure Flutter is initialized
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

    private fun isBatteryOptimizationDisabled(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val packageName = packageName
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true // Battery optimization settings only available on Android M and above
        }
    }
    
    private fun getBatteryLevel(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        }
        return -1
    }

    private fun requestDisableBatteryOptimization(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent().apply {
                action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                data = Uri.parse("package:$packageName")
            }
            
            try {
                startActivityForResult(intent, BATTERY_OPTIMIZATION_REQUEST_CODE)
                result.success(true)
            } catch (e: Exception) {
                result.error("UNAVAILABLE", "Battery optimization request failed", e.message)
            }
        } else {
            result.success(true) // Not applicable for older Android versions
        }
    }

    private fun openBatteryOptimizationSettings(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent().apply {
                action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            }
            
            try {
                startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                result.error("UNAVAILABLE", "Cannot open battery optimization settings", e.message)
            }
        } else {
            result.success(false) // Not applicable for older Android versions
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == BATTERY_OPTIMIZATION_REQUEST_CODE) {
            // Check the current battery optimization status
            val isDisabled = isBatteryOptimizationDisabled()
            
            // Send result back through the method channel
            methodChannel.invokeMethod(
                "batteryOptimizationResult", 
                isDisabled
            )
        }
    }
    
    private fun updateDashboardWidget(hostsDataStr: String, servicesDataStr: String) {
        try {
            val hostsData = JSONObject(hostsDataStr)
            val servicesData = JSONObject(servicesDataStr)
            
            // Save the data and update the widget
            DashboardWidgetProvider.saveDashboardData(applicationContext, hostsData, servicesData)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
