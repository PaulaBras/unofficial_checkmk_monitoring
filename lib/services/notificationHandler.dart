import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiRequest.dart';
import '../services/secureStorage.dart';

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

class CheckmkNotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiRequest _apiRequest = ApiRequest();
  final SecureStorage _secureStorage = SecureStorage();
  
  Timer? _backgroundCheckTimer;
  Map<String, dynamic> _previousHostStatus = {};
  Map<String, dynamic> _previousServiceStatus = {};

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
  }

  void start() {
    _startPeriodicStatusCheck();
  }

  void stop() {
    _backgroundCheckTimer?.cancel();
  }

  void _startPeriodicStatusCheck() async {
    // Check if background notifications are enabled
    String? enableNotifications = await _secureStorage.readSecureData('enableNotifications');
    bool isNotificationEnabled = enableNotifications?.toLowerCase() == 'true';

    if (isNotificationEnabled) {
      _backgroundCheckTimer?.cancel();
      _backgroundCheckTimer = Timer.periodic(Duration(seconds: 60), (_) {
        _performBackgroundCheck();
      });
    }
  }

  void _performBackgroundCheck() async {
    try {
      var hostStatus = await _fetchHostStatus();
      var serviceStatus = await _fetchServiceStatus();

      _checkAndNotifyHostChanges(hostStatus);
      _checkAndNotifyServiceChanges(serviceStatus);
    } catch (e) {
      print('Background check error: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchHostStatus() async {
    try {
      var response = await _apiRequest.Request('objects/host');
      return response ?? {};
    } catch (e) {
      print('Error fetching host status: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _fetchServiceStatus() async {
    try {
      var response = await _apiRequest.Request('objects/service');
      return response ?? {};
    } catch (e) {
      print('Error fetching service status: $e');
      return {};
    }
  }

  void _checkAndNotifyHostChanges(Map<String, dynamic> currentStatus) {
    currentStatus.forEach((hostName, hostDetails) {
      var previousHostDetails = _previousHostStatus[hostName];
      var currentState = hostDetails['status'];
      
      // Always notify for hosts (up, down, unreachable)
      if (previousHostDetails == null || 
          previousHostDetails['status'] != currentState) {
        _showNotification(
          title: 'Host Status Change: $hostName',
          body: 'Status: ${_hostStateMap[currentState] ?? 'Unknown'}',
          payload: 'host_status_change'
        );
      }
    });

    _previousHostStatus = currentStatus;
  }

  void _checkAndNotifyServiceChanges(Map<String, dynamic> currentStatus) async {
    // Load service state notification settings
    Map<String, bool> serviceStateSettings = {
      'green': true,
      'warning': true,
      'critical': true,
      'unknown': true,
    };

    for (var state in serviceStateSettings.keys) {
      String? savedSetting = await _secureStorage.readSecureData('notify_$state');
      serviceStateSettings[state] = savedSetting?.toLowerCase() != 'false';
    }

    currentStatus.forEach((serviceName, serviceDetails) {
      var previousServiceDetails = _previousServiceStatus[serviceName];
      var currentState = serviceDetails['status'];
      var currentStateString = _serviceStateMap[currentState] ?? 'unknown';
      
      // Check if current attempts equal max attempts
      int currentAttempts = serviceDetails['current_attempt'] ?? 0;
      int maxAttempts = serviceDetails['max_attempts'] ?? 1;
      
      // Send notification if:
      // 1. Status changed
      // 2. Current attempts equal max attempts
      // 3. Notification for this state is enabled
      bool statusChanged = previousServiceDetails == null || 
          previousServiceDetails['status'] != currentState;
      
      if (statusChanged && 
          currentAttempts == maxAttempts && 
          (serviceStateSettings[currentStateString] ?? true)) {
        _showNotification(
          title: 'Service Status Change: $serviceName',
          body: 'Status: $currentStateString, Attempts: $currentAttempts/$maxAttempts',
          payload: 'service_status_change'
        );
      }
    });

    _previousServiceStatus = currentStatus;
  }

  Future<void> _showNotification({
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

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Public method to match the previous implementation's signature
  Future<void> sendNotification(String title, String body, {String? payload}) async {
    await _showNotification(
      title: title, 
      body: body, 
      payload: payload
    );
  }
}
