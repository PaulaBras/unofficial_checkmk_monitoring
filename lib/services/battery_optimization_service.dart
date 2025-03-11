import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('checkmk/ptp_4_monitoring_app');
  static const String _batteryOptimizationKey = 'battery_optimization_requested';

  // Check if battery optimization is disabled for the app
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) {
      return true; // Only relevant for Android
    }

    try {
      final bool result = await _channel.invokeMethod('isBatteryOptimizationDisabled');
      return result;
    } on PlatformException catch (e) {
      // Error checking battery optimization status
      return false;
    }
  }

  // Request to disable battery optimization
  Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) {
      return true; // Only relevant for Android
    }

    try {
      final bool result = await _channel.invokeMethod('requestDisableBatteryOptimization');
      
      // Mark that we've requested battery optimization
      if (result) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_batteryOptimizationKey, true);
      }
      
      return result;
    } on PlatformException catch (e) {
      // Error requesting battery optimization
      return false;
    }
  }

  // Open battery optimization settings
  Future<bool> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) {
      return false; // Only relevant for Android
    }

    try {
      final bool result = await _channel.invokeMethod('openBatteryOptimizationSettings');
      return result;
    } on PlatformException catch (e) {
      // Error opening battery optimization settings
      return false;
    }
  }

  // Check if we've already requested battery optimization
  Future<bool> hasRequestedBatteryOptimization() async {
    if (!Platform.isAndroid) {
      return true; // Only relevant for Android
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_batteryOptimizationKey) ?? false;
  }

  // Mark that we've shown the battery optimization dialog
  Future<void> markBatteryOptimizationRequested() async {
    if (!Platform.isAndroid) {
      return; // Only relevant for Android
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_batteryOptimizationKey, true);
  }
}
