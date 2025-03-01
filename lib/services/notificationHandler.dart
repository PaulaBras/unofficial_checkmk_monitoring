import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/setup/AreNotificationsActive.dart';
import '../services/apiRequest.dart';
import '../services/secureStorage.dart';

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

class CheckmkNotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiRequest _apiRequest = ApiRequest();
  final SecureStorage _secureStorage = SecureStorage();
  final AreNotificationsActive _notificationsActive = AreNotificationsActive();
  
  Timer? _backgroundCheckTimer;
  Map<String, dynamic> _previousHostStatus = {};
  Map<String, dynamic> _previousServiceStatus = {};
  Set<String> _notifiedHosts = {};
  Set<String> _notifiedServices = {};
  bool _isAppInBackground = false;
  int _persistentNotificationId = 9999; // Unique ID for the persistent notification

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
  void setAppInBackground(bool isInBackground) {
    _isAppInBackground = isInBackground;
    
    if (isInBackground) {
      _showPersistentNotification();
    } else {
      _removePersistentNotification();
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

  void start() {
    _startPeriodicStatusCheck(initialCheck: true);
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

    if (isNotificationEnabled) {
      _backgroundCheckTimer?.cancel();
      
      // Perform initial check if specified
      if (initialCheck) {
        await _performBackgroundCheck();
      }
      
      _backgroundCheckTimer = Timer.periodic(Duration(seconds: 60), (_) {
        _performBackgroundCheck();
      });
    } else {
      _backgroundCheckTimer?.cancel();
      _removePersistentNotification();
    }
  }

  Future<void> _performBackgroundCheck() async {
    try {
      // Check if notifications should be active based on schedule
      bool shouldNotify = await _notificationsActive.areNotificationsActive();
      
      if (!shouldNotify || !_isAppInBackground) {
        // Skip notification checks if notifications are not active or app is in foreground
        return;
      }
      
      var hostResponse = await _fetchHostStatus();
      var serviceResponse = await _fetchServiceStatus();

      print('[DEBUG] Background Check:');
      print('  - App in Background: $_isAppInBackground');
      print('  - Notifications Active: $shouldNotify');
      print('  - Host Status: ${hostResponse != null ? 'Received' : 'Failed'}');
      print('  - Service Status: ${serviceResponse != null ? 'Received' : 'Failed'}');

      if (hostResponse != null && serviceResponse != null) {
        _checkAndNotifyHostChanges(hostResponse['value']);
        await _checkAndNotifyServiceChanges(serviceResponse['value']);
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

  void _checkAndNotifyHostChanges(List<dynamic> currentStatus) {
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
