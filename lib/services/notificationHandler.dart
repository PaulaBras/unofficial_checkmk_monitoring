import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/setup/AreNotificationsActive.dart';
import '../services/apiRequest.dart';
import '../services/secureStorage.dart';
import '../services/battery_optimization_service.dart';

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

class CheckmkNotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiRequest _apiRequest = ApiRequest();
  final SecureStorage _secureStorage = SecureStorage();
  final AreNotificationsActive _notificationsActive = AreNotificationsActive();
  final BatteryOptimizationService _batteryService = BatteryOptimizationService();
  
  Timer? _backgroundCheckTimer;
  Map<String, dynamic> _previousHostStatus = {};
  Map<String, dynamic> _previousServiceStatus = {};
  final String _previousHostStatusKey = 'previous_host_status';
  final String _previousServiceStatusKey = 'previous_service_status';
  Set<String> _notifiedHosts = {};
  Set<String> _notifiedServices = {};
  bool _isAppInBackground = false;
  bool _isBatteryOptimizationDisabled = false;
  int _persistentNotificationId = 9999; // Unique ID for the persistent notification
  
  // Default polling intervals in seconds
  static const int _defaultForegroundInterval = 60;
  static const int _defaultBackgroundInterval = 300; // 5 minutes
  static const int _optimizedBackgroundInterval = 120; // 2 minutes
  static const int _lowPowerBackgroundInterval = 900; // 15 minutes

  // Map host states to their string representations
  final Map<int, String> _hostStateMap = {
    0: 'Up',
    1: 'Down',
    2: 'Unreachable'
  };

  // Map service states to their string representations
  final Map<int, String> _serviceStateMap = {
    0: 'green',
    1: 'warning',
    2: 'critical',
    3: 'unknown'
  };
  
  // Current polling interval in seconds
  int _currentPollingInterval = _defaultForegroundInterval;

  // Methods to match previous NotificationService implementation
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notifications_enabled') ?? true,
      'schedule': prefs.getString('notifications_schedule') ?? '',
    };
  }

  Future<void> saveNotificationSettings({
    required bool enabled, 
    String? schedule
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (schedule != null) {
      await prefs.setString('notifications_schedule', schedule);
    }
  }
  
  // Track app lifecycle state
  Future<void> setAppInBackground(bool isInBackground) async {
    _isAppInBackground = isInBackground;
    
    // Check battery optimization status
    _isBatteryOptimizationDisabled = await _batteryService.isBatteryOptimizationDisabled();
    
    if (isInBackground) {
      _showPersistentNotification();
      
      // Adjust polling interval based on battery optimization status
      await _adjustPollingInterval();
    } else {
      _removePersistentNotification();
      
      // Reset to foreground polling interval
      _setPollingInterval(_defaultForegroundInterval);
    }
  }
  
  // Adjust polling interval based on app state and battery optimization
  Future<void> _adjustPollingInterval() async {
    if (!_isAppInBackground) {
      // App is in foreground, use default interval
      _setPollingInterval(_defaultForegroundInterval);
      return;
    }
    
    // Get battery level if possible
    int batteryLevel = await _getBatteryLevel();
    bool isLowBattery = batteryLevel > 0 && batteryLevel <= 15;
    
    if (isLowBattery) {
      // Low battery mode - use longest interval
      _setPollingInterval(_lowPowerBackgroundInterval);
    } else if (_isBatteryOptimizationDisabled) {
      // Battery optimization is disabled - use optimized interval
      _setPollingInterval(_optimizedBackgroundInterval);
    } else {
      // Default background interval
      _setPollingInterval(_defaultBackgroundInterval);
    }
    
    print('[DEBUG] Adjusted polling interval: $_currentPollingInterval seconds');
    print('  - App in background: $_isAppInBackground');
    print('  - Battery optimization disabled: $_isBatteryOptimizationDisabled');
    print('  - Battery level: $batteryLevel%');
    print('  - Low battery mode: $isLowBattery');
  }
  
  // Set polling interval and restart timer if needed
  void _setPollingInterval(int seconds) {
    if (_currentPollingInterval != seconds) {
      _currentPollingInterval = seconds;
      
      // Restart timer with new interval if it's running
      if (_backgroundCheckTimer != null && _backgroundCheckTimer!.isActive) {
        _backgroundCheckTimer!.cancel();
        _backgroundCheckTimer = Timer.periodic(Duration(seconds: _currentPollingInterval), (_) {
          _performBackgroundCheck();
        });
      }
    }
  }
  
  // Get battery level (returns -1 if not available)
  Future<int> _getBatteryLevel() async {
    try {
      final batteryLevel = await MethodChannel('checkmk/ptp_4_monitoring_app')
          .invokeMethod<int>('getBatteryLevel');
      return batteryLevel ?? -1;
    } on PlatformException {
      return -1;
    }
  }

  Future<void> requestNotificationsPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    // Initialize notification channels
    await _initializeNotificationChannels();
  }

  Future<void> _initializeNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel statusChannel = AndroidNotificationChannel(
        'checkmk_status_channel',
        'Status Changes',
        description: 'Notifications for CheckMK status changes',
        importance: Importance.high,
      );
      
      const AndroidNotificationChannel persistentChannel = AndroidNotificationChannel(
        'checkmk_persistent_channel',
        'Background Service',
        description: 'Notification indicating the app is running in the background',
        importance: Importance.low,
      );
      
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(statusChannel);
          
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(persistentChannel);
    }
  }

  Future<void> start() async {
    // Load previous statuses from storage
    await _loadPreviousStatuses();
    
    // Check battery optimization status
    _isBatteryOptimizationDisabled = await _batteryService.isBatteryOptimizationDisabled();
    
    // Start periodic status check
    await _startPeriodicStatusCheck(initialCheck: true);
  }
  
  Future<void> _loadPreviousStatuses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedHostStatus = prefs.getString(_previousHostStatusKey);
    String? savedServiceStatus = prefs.getString(_previousServiceStatusKey);
    
    if (savedHostStatus != null) {
      try {
        Map<String, dynamic> decoded = Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            jsonDecode(savedHostStatus) as Map
          ).map((key, value) => MapEntry(key, value as dynamic))
        );
        _previousHostStatus = decoded;
        print('[DEBUG] Loaded previous host status from storage: ${_previousHostStatus.length} hosts');
      } catch (e) {
        print('Error loading previous host status: $e');
        _previousHostStatus = {};
      }
    }
    
    if (savedServiceStatus != null) {
      try {
        Map<String, dynamic> decoded = Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            jsonDecode(savedServiceStatus) as Map
          ).map((key, value) => MapEntry(key, value as dynamic))
        );
        _previousServiceStatus = decoded;
        print('[DEBUG] Loaded previous service status from storage: ${_previousServiceStatus.length} services');
      } catch (e) {
        print('Error loading previous service status: $e');
        _previousServiceStatus = {};
      }
    }
  }
  
  Future<void> _savePreviousStatuses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_previousHostStatusKey, jsonEncode(_previousHostStatus));
      await prefs.setString(_previousServiceStatusKey, jsonEncode(_previousServiceStatus));
      print('[DEBUG] Saved statuses to storage: ${_previousHostStatus.length} hosts, ${_previousServiceStatus.length} services');
    } catch (e) {
      print('Error saving previous statuses: $e');
    }
  }

  void stop() {
    _backgroundCheckTimer?.cancel();
    _removePersistentNotification();
  }

  Future<void> _startPeriodicStatusCheck({bool initialCheck = false}) async {
    // Attempt to read notifications setting, default to true if not set
    String? enableNotifications = await _secureStorage.readSecureData('enableNotifications') ?? 'true';

    bool isNotificationEnabled = enableNotifications.toLowerCase() == 'true';

    print('[DEBUG] Notification Settings:');
    print('  - Notifications Enabled: $isNotificationEnabled');
    print('  - Enable Notifications Value: $enableNotifications');
    print('  - Battery Optimization Disabled: $_isBatteryOptimizationDisabled');
    print('  - Current Polling Interval: $_currentPollingInterval seconds');

    if (isNotificationEnabled) {
      _backgroundCheckTimer?.cancel();
      
      // Perform initial check if specified
      if (initialCheck) {
        await _performBackgroundCheck(isInitialCheck: true);
      }
      
      // Adjust polling interval based on app state and battery optimization
      await _adjustPollingInterval();
      
      _backgroundCheckTimer = Timer.periodic(Duration(seconds: _currentPollingInterval), (_) {
        _performBackgroundCheck();
      });
    } else {
      _backgroundCheckTimer?.cancel();
      _removePersistentNotification();
    }
  }

  Future<void> _performBackgroundCheck({bool isInitialCheck = false}) async {
    try {
      // Check if notifications should be active based on schedule
      bool shouldNotify = await _notificationsActive.areNotificationsActive();
      
      // If this is an initial check after app restart, we don't want to send notifications
      // We just want to update the status maps
      bool skipNotifications = isInitialCheck || !_isAppInBackground || !shouldNotify;
      
      if (skipNotifications && !isInitialCheck) {
        // Skip notification checks if notifications are not active or app is in foreground
        // But continue if it's an initial check to update the status maps
        return;
      }
      
      var hostResponse = await _fetchHostStatus();
      var serviceResponse = await _fetchServiceStatus();

      print('[DEBUG] Background Check:');
      print('  - App in Background: $_isAppInBackground');
      print('  - Notifications Active: $shouldNotify');
      print('  - Initial Check: $isInitialCheck');
      print('  - Skip Notifications: $skipNotifications');
      print('  - Host Status: ${hostResponse != null ? 'Received' : 'Failed'}');
      print('  - Service Status: ${serviceResponse != null ? 'Received' : 'Failed'}');
      print('  - Current Polling Interval: $_currentPollingInterval seconds');

      if (hostResponse != null && serviceResponse != null) {
        // If this is an initial check, update the status maps without sending notifications
        if (isInitialCheck) {
          await _updateHostStatusWithoutNotifications(hostResponse['value']);
          await _updateServiceStatusWithoutNotifications(serviceResponse['value']);
        } else {
          await _checkAndNotifyHostChanges(hostResponse['value']);
          await _checkAndNotifyServiceChanges(serviceResponse['value']);
        }
      }
      
      // Periodically check and adjust polling interval based on battery status
      if (!isInitialCheck && _isAppInBackground) {
        await _adjustPollingInterval();
      }
    } catch (e) {
      print('Background check error: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchHostStatus() async {
    try {
      var response = await _apiRequest.Request('domain-types/host/collections/all?columns=state');
      return response;
    } catch (e) {
      print('Error fetching host status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchServiceStatus() async {
    try {
      var response = await _apiRequest.Request('domain-types/service/collections/all?columns=state');
      return response;
    } catch (e) {
      print('Error fetching service status: $e');
      return null;
    }
  }

  // Update host status without sending notifications (for initial check)
  Future<void> _updateHostStatusWithoutNotifications(List<dynamic> currentStatus) async {
    // Convert list to map for easier processing
    Map<String, dynamic> hostMap = {
      for (var host in currentStatus)
        host['extensions']['name']: {'status': host['extensions']['state']}
    };
    
    _previousHostStatus = hostMap;
    
    // Save updated status to storage
    await _savePreviousStatuses();
    
    print('[DEBUG] Updated host status without notifications: ${hostMap.length} hosts');
  }
  
  // Update service status without sending notifications (for initial check)
  Future<void> _updateServiceStatusWithoutNotifications(List<dynamic> currentStatus) async {
    // Convert list to map for easier processing
    Map<String, dynamic> serviceMap = {
      for (var service in currentStatus)
        service['extensions']['description']: {
          'name': service['extensions']['host_name'],
          'status': service['extensions']['state'],
          'current_attempt': service['extensions']['current_attempt'] ?? 5,
          'max_attempts': service['extensions']['max_check_attempts'] ?? 5
        }
    };
    
    _previousServiceStatus = serviceMap;
    
    // Save updated status to storage
    await _savePreviousStatuses();
    
    print('[DEBUG] Updated service status without notifications: ${serviceMap.length} services');
  }

  Future<void> _checkAndNotifyHostChanges(List<dynamic> currentStatus) async {
    // Only send notifications if app is in background
    if (!_isAppInBackground) return;
    
    // Convert list to map for easier processing
    Map<String, dynamic> hostMap = {
      for (var host in currentStatus)
        host['extensions']['name']: {'status': host['extensions']['state']}
    };

    hostMap.forEach((hostName, hostDetails) {
      var previousHostDetails = _previousHostStatus[hostName];
      var currentState = hostDetails['status'];
      
      // Notify for hosts that have a status change
      bool shouldNotify = 
          (previousHostDetails == null || 
           previousHostDetails['status'] != currentState);
      
      if (currentState != 0 || 
          (previousHostDetails != null && previousHostDetails['status'] != 0)) {
        print('[DEBUG] Host Status Check:');
        print('  - Host: $hostName');
        print('  - Current State: ${_hostStateMap[currentState] ?? 'Unknown'}');
        print('  - Previous State: ${previousHostDetails != null ? _hostStateMap[previousHostDetails['status']] : 'None'}');
        print('  - Should Notify: $shouldNotify');
      }

      if (shouldNotify) {
        _showStatusNotification(
          title: 'Host Status: $hostName',
          body: 'Status: ${_hostStateMap[currentState] ?? 'Unknown'}',
          payload: 'host_status_change'
        );
        _notifiedHosts.add(hostName);
      }
    });

    _previousHostStatus = hostMap;
    
    // Save updated status to storage
    await _savePreviousStatuses();
  }

  Future<void> _checkAndNotifyServiceChanges(List<dynamic> currentStatus) async {
    // Only send notifications if app is in background
    if (!_isAppInBackground) return;
    
    // Load service state notification settings
    Map<String, bool> serviceStateSettings = {
      'green': true,
      'warning': true,
      'critical': true,
      'unknown': true,
    };

    // Asynchronously load notification settings for each state
    await Future.wait(serviceStateSettings.keys.map((state) async {
      String? savedSetting = await _secureStorage.readSecureData('notify_$state');
      serviceStateSettings[state] = savedSetting?.toLowerCase() != 'false';
      print('[DEBUG] Notification Setting for $state: ${serviceStateSettings[state]}');
    }));

    // Convert list to map for easier processing
    Map<String, dynamic> serviceMap = {
      for (var service in currentStatus)
        service['extensions']['description']: {
          'name': service['extensions']['host_name'],
          'status': service['extensions']['state'],
          'current_attempt': service['extensions']['current_attempt'] ?? 5,
          'max_attempts': service['extensions']['max_check_attempts'] ?? 5
        }
    };

    serviceMap.forEach((serviceName, serviceDetails) {
      var previousServiceDetails = _previousServiceStatus[serviceName];
      var currentState = serviceDetails['status'];
      var currentStateString = _serviceStateMap[currentState] ?? 'unknown';
      
      // Check if current attempts equal max attempts
      int currentAttempts = serviceDetails['current_attempt'] ?? 0;
      int maxAttempts = serviceDetails['max_attempts'] ?? 1;
      
      // Send notification if:
      // 1. Status changed
      // 2. Not just a transition to green
      bool shouldNotify = 
          (previousServiceDetails == null || 
           previousServiceDetails['status'] != currentState) &&
          (currentStateString != 'green' || 
           (previousServiceDetails != null && 
            _serviceStateMap[previousServiceDetails['status']] != 'green'));
      
      // Only notify if the state setting is enabled
      if (serviceStateSettings[currentStateString] != true) {
        shouldNotify = false;
      }
      
      if (currentStateString != 'green' || 
          (previousServiceDetails != null && 
           _serviceStateMap[previousServiceDetails['status']] != 'green')) {
        print('[DEBUG] Service Status Check:');
        print('  - Service: $serviceName');
        print('  - Host: ${serviceDetails['name']}');
        print('  - Current State: $currentStateString');
        print('  - Current Attempts: $currentAttempts');
        print('  - Max Attempts: $maxAttempts');
        print('  - Previous State: ${previousServiceDetails != null ? _serviceStateMap[previousServiceDetails['status']] : 'None'}');
        print('  - Should Notify: $shouldNotify');
      }

      if (shouldNotify) {
        _showStatusNotification(
          title: 'Service Status Change: $serviceName',
          body: 'Host: ${serviceDetails['name']}, Status: $currentStateString, Attempts: $currentAttempts/$maxAttempts',
          payload: 'service_status_change'
        );
        _notifiedServices.add(serviceName);
      }
    });

    _previousServiceStatus = serviceMap;
    
    // Save updated status to storage
    await _savePreviousStatuses();
  }

  Future<void> _showStatusNotification({
    required String title, 
    required String body, 
    String? payload
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'checkmk_status_channel',
      'Status Changes',
      channelDescription: 'Notifications for CheckMK status changes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    print('[DEBUG] Showing Status Notification:');
    print('  - Title: $title');
    print('  - Body: $body');
    print('  - Payload: $payload');

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
  
  Future<void> _showPersistentNotification() async {
    // Check if notifications are enabled
    String? enableNotifications = await _secureStorage.readSecureData('enableNotifications') ?? 'true';
    bool isNotificationEnabled = enableNotifications.toLowerCase() == 'true';
    
    if (!isNotificationEnabled) return;
    
    // Create a persistent notification to show the app is running in background
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'checkmk_persistent_channel',
      'Background Service',
      channelDescription: 'Notification indicating the app is running in the background',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    print('[DEBUG] Showing Persistent Notification');

    await flutterLocalNotificationsPlugin.show(
      _persistentNotificationId,
      'CheckMK Monitoring Active',
      'Monitoring hosts and services in the background',
      platformDetails,
    );
  }
  
  Future<void> _removePersistentNotification() async {
    await flutterLocalNotificationsPlugin.cancel(_persistentNotificationId);
  }

  // Public method to match the previous implementation's signature
  Future<void> sendNotification(String title, String body, {String? payload}) async {
    await _showStatusNotification(
      title: title, 
      body: body, 
      payload: payload
    );
  }
}
