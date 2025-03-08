import 'dart:convert';
import 'package:flutter/services.dart';
import '/services/apiRequest.dart';

class DashboardWidgetService {
  static const MethodChannel _channel = MethodChannel('checkmk/dashboard_widget');
  static final DashboardWidgetService _instance = DashboardWidgetService._internal();
  
  factory DashboardWidgetService() {
    return _instance;
  }
  
  DashboardWidgetService._internal() {
    // Set up method channel handler for widget refresh requests
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  // Handle method calls from the platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'refreshWidgetData':
        // Widget is requesting a refresh
        return updateWidget();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }
  
  /// Updates the dashboard widget with the latest data
  Future<bool> updateWidget() async {
    try {
      // Fetch the latest data
      final hostsData = await _fetchHostsData();
      final servicesData = await _fetchServicesData();
      
      if (hostsData != null && servicesData != null) {
        // Convert to JSON strings
        final hostsJson = jsonEncode(hostsData);
        final servicesJson = jsonEncode(servicesData);
        
        // Update the widget through the platform channel
        final result = await _channel.invokeMethod<bool>(
          'updateDashboardWidget',
          {
            'hostsData': hostsJson,
            'servicesData': servicesJson,
          },
        );
        
        return result ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error updating dashboard widget: $e');
      return false;
    }
  }
  
  /// Fetches hosts data and formats it for the widget
  Future<Map<String, dynamic>?> _fetchHostsData() async {
    try {
      final api = ApiRequest();
      final response = await api.Request('domain-types/host/collections/all?columns=state');
      
      if (response != null && response.containsKey('value')) {
        final hostData = response['value'];
        
        // Count hosts by state
        final ok = hostData.where((item) => item['extensions']['state'] == 0).length;
        final down = hostData.where((item) => item['extensions']['state'] == 1).length;
        final unreach = hostData.where((item) => item['extensions']['state'] == 2).length;
        
        return {
          'ok': ok,
          'down': down,
          'unreach': unreach,
          'total': ok + down + unreach,
        };
      }
      
      return null;
    } catch (e) {
      print('Error fetching hosts data: $e');
      return null;
    }
  }
  
  /// Fetches services data and formats it for the widget
  Future<Map<String, dynamic>?> _fetchServicesData() async {
    try {
      final api = ApiRequest();
      final response = await api.Request('domain-types/service/collections/all?columns=state');
      
      if (response != null && response.containsKey('value')) {
        final serviceData = response['value'];
        
        // Count services by state
        final ok = serviceData.where((item) => item['extensions']['state'] == 0).length;
        final warn = serviceData.where((item) => item['extensions']['state'] == 1).length;
        final crit = serviceData.where((item) => item['extensions']['state'] == 2).length;
        final unknown = serviceData.length - ok - warn - crit;
        
        return {
          'ok': ok,
          'warn': warn,
          'crit': crit,
          'unknown': unknown,
          'total': ok + warn + crit + unknown,
        };
      }
      
      return null;
    } catch (e) {
      print('Error fetching services data: $e');
      return null;
    }
  }
}
