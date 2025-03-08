package com.checkmk.unofficial_checkmk_monitoring

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DashboardWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_UPDATE_WIDGET = "com.checkmk.unofficial_checkmk_monitoring.ACTION_UPDATE_WIDGET"
        const val PREFS_NAME = "com.checkmk.unofficial_checkmk_monitoring.DashboardWidget"
        const val PREF_HOSTS_DATA = "hosts_data"
        const val PREF_SERVICES_DATA = "services_data"
        const val PREF_LAST_UPDATED = "last_updated"

        // Method to update all widgets
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, DashboardWidgetProvider::class.java)
            )
            
            // Update all widgets
            val intent = Intent(context, DashboardWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(intent)
        }

        // Method to save dashboard data
        fun saveDashboardData(context: Context, hostsData: JSONObject, servicesData: JSONObject) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()
            
            editor.putString(PREF_HOSTS_DATA, hostsData.toString())
            editor.putString(PREF_SERVICES_DATA, servicesData.toString())
            editor.putLong(PREF_LAST_UPDATED, System.currentTimeMillis())
            editor.apply()
            
            // Update all widgets with new data
            updateAllWidgets(context)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update each widget
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == ACTION_UPDATE_WIDGET) {
            // Force a manual update from the app
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, DashboardWidgetProvider::class.java)
            )
            
            // Trigger a data refresh by calling the Flutter method channel
            try {
                // This will attempt to refresh data from the app if it's running
                // If not, it will just update with existing data
                val packageManager = context.packageManager
                val launchIntent = packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    launchIntent.putExtra("refresh_widget", true)
                    context.startActivity(launchIntent)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            
            // Update the widget with current data
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Get the saved data
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hostsDataStr = prefs.getString(PREF_HOSTS_DATA, null)
        val servicesDataStr = prefs.getString(PREF_SERVICES_DATA, null)
        val lastUpdated = prefs.getLong(PREF_LAST_UPDATED, 0)
        
        // Create RemoteViews for the widget layout
        val views = RemoteViews(context.packageName, R.layout.dashboard_widget)
        
        // Set up click intent for the widget (open the app)
        val openAppIntent = PendingIntent.getActivity(
            context,
            0,
            context.packageManager.getLaunchIntentForPackage(context.packageName),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        
        // Make the entire widget clickable to open the app
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent)
        
        // Set up refresh button click intent
        val refreshIntent = Intent(context, DashboardWidgetProvider::class.java)
        refreshIntent.action = ACTION_UPDATE_WIDGET
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context,
            1, // Use a different request code to avoid conflicts
            refreshIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
        
        // Update the widget with data
        if (hostsDataStr != null && servicesDataStr != null) {
            try {
                val hostsData = JSONObject(hostsDataStr)
                val servicesData = JSONObject(servicesDataStr)
                
                // Update hosts data
                views.setTextViewText(R.id.hosts_up, hostsData.optInt("ok", 0).toString())
                views.setTextViewText(R.id.hosts_down, hostsData.optInt("down", 0).toString())
                views.setTextViewText(R.id.hosts_unreach, hostsData.optInt("unreach", 0).toString())
                
                // Update services data
                views.setTextViewText(R.id.services_ok, servicesData.optInt("ok", 0).toString())
                views.setTextViewText(R.id.services_warn, servicesData.optInt("warn", 0).toString())
                views.setTextViewText(R.id.services_crit, servicesData.optInt("crit", 0).toString())
                views.setTextViewText(R.id.services_unknown, servicesData.optInt("unknown", 0).toString())
                
                // Format the last updated time
                val dateFormat = SimpleDateFormat("dd.MM.yyyy, HH:mm", Locale.getDefault())
                val lastUpdatedStr = "Last updated: ${dateFormat.format(Date(lastUpdated))}"
                views.setTextViewText(R.id.last_updated, lastUpdatedStr)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
