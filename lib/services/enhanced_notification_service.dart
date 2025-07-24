import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification.dart';
import '../services/apiRequest.dart';
import '../services/host_service.dart';
import '../services/service_service.dart';
import '../utils/notification_constants.dart';

/// Enhanced notification service that triggers notifications when current attempts match max attempts
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ApiRequest _apiRequest = ApiRequest();
  final HostService _hostService = HostService();
  final ServiceService _serviceService = ServiceService();

  Timer? _backgroundTimer;
  bool _isInitialized = false;
  bool _isAppInBackground = false;
  int _currentInterval = NotificationConstants.foregroundCheckInterval;

  // Track which items have already been notified to prevent spam
  Set<String> _notifiedItems = {};
  Map<String, NotificationRequest> _previousState = {};

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeNotificationPlugin();
    await _createNotificationChannels();
    await _loadPreviousState();

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized successfully');
  }

  Future<void> _initializeNotificationPlugin() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Status notification channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationConstants.statusChannelId,
            NotificationConstants.statusChannelName,
            description: NotificationConstants.statusChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Persistent notification channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationConstants.persistentChannelId,
            NotificationConstants.persistentChannelName,
            description: NotificationConstants.persistentChannelDescription,
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
        '[NotificationService] Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific screen
  }

  /// Start monitoring with the specified requirement:
  /// Check every minute for services/hosts where currentAttempt == maxAttempts
  Future<void> startMonitoring() async {
    if (!_isInitialized) {
      await initialize();
    }

    await _startPeriodicChecks();
    await _showPersistentNotification();

    debugPrint(
        '[NotificationService] Started monitoring with ${_currentInterval}s interval');
  }

  /// Stop monitoring
  Future<void> stopMonitoring() async {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    await _hidePersistentNotification();

    debugPrint('[NotificationService] Stopped monitoring');
  }

  /// Set app background state and adjust monitoring interval
  Future<void> setAppInBackground(bool isInBackground) async {
    _isAppInBackground = isInBackground;

    if (isInBackground) {
      _currentInterval = NotificationConstants.backgroundCheckInterval;
      await _showPersistentNotification();
    } else {
      _currentInterval = NotificationConstants.foregroundCheckInterval;
      await _hidePersistentNotification();
    }

    // Restart timer with new interval
    if (_backgroundTimer != null) {
      await _startPeriodicChecks();
    }

    debugPrint(
        '[NotificationService] App background: $isInBackground, interval: ${_currentInterval}s');
  }

  Future<void> _startPeriodicChecks() async {
    _backgroundTimer?.cancel();

    // Perform initial check
    await _performNotificationCheck();

    // Start periodic timer
    _backgroundTimer = Timer.periodic(
      Duration(seconds: _currentInterval),
      (_) => _performNotificationCheck(),
    );
  }

  /// Main notification check method - implements the core requirement
  Future<void> _performNotificationCheck() async {
    try {
      debugPrint('[NotificationService] Performing notification check...');

      // Check if notifications are enabled
      if (!await _areNotificationsEnabled()) {
        debugPrint(
            '[NotificationService] Notifications disabled, skipping check');
        return;
      }

      // Fetch current host and service data
      final hosts = await _hostService.getAllHosts();
      final services = await _serviceService.getAllServices();

      final List<NotificationRequest> notificationCandidates = [];

      // Check hosts that are DOWN or UNREACHABLE
      // Note: Hosts typically don't have attempt info in standard CheckMK,
      // so we'll focus on services for attempt-based notifications
      for (final host in hosts) {
        if (NotificationConstants.problematicHostStates.contains(host.state)) {
          // For hosts, we'll create a basic notification without attempt checking
          // since most CheckMK installations don't track host check attempts
          final hostNotification = _createHostNotificationRequest(host);
          if (hostNotification.shouldTriggerNotification) {
            notificationCandidates.add(hostNotification);
          }
        }
      }

      // Check services that are WARNING, CRITICAL, or UNKNOWN and currentAttempt == maxAttempts
      for (final service in services) {
        if (NotificationConstants.problematicServiceStates
            .contains(service.state)) {
          final serviceNotification =
              NotificationRequest.fromServiceModel(service);
          if (serviceNotification.shouldTriggerNotification) {
            notificationCandidates.add(serviceNotification);
          }
        }
      }

      // Process notification candidates
      await _processNotificationCandidates(notificationCandidates);

      debugPrint(
          '[NotificationService] Check completed. Found ${notificationCandidates.length} candidates');
    } catch (e) {
      debugPrint('[NotificationService] Error during notification check: $e');
    }
  }

  NotificationRequest _createHostNotificationRequest(host) {
    // Create notification request from Host model
    // Since hosts typically don't have attempt tracking, we'll use state-based notifications
    return NotificationRequest(
      id: 'host_${host.name}',
      type: 'host',
      name: host.name,
      hostName: host.name,
      state: host.state,
      currentAttempt: 1, // Default for hosts
      maxAttempts: 1, // Default for hosts
      pluginOutput: 'Host is ${_getHostStateName(host.state)}',
      timestamp: DateTime.now(),
    );
  }

  String _getHostStateName(int state) {
    switch (state) {
      case 0:
        return 'UP';
      case 1:
        return 'DOWN';
      case 2:
        return 'UNREACHABLE';
      default:
        return 'UNKNOWN';
    }
  }

  Future<void> _processNotificationCandidates(
      List<NotificationRequest> candidates) async {
    for (final candidate in candidates) {
      // Skip if we've already notified about this item recently
      if (_notifiedItems.contains(candidate.id)) {
        continue;
      }

      // Check if this is a new issue or state change
      final previousState = _previousState[candidate.id];
      final shouldNotify = _shouldSendNotification(candidate, previousState);

      if (shouldNotify) {
        await _sendNotification(candidate);
        _notifiedItems.add(candidate.id);

        // Clean up old notifications to prevent memory issues
        await _cleanupOldNotifications();
      }

      // Update previous state
      _previousState[candidate.id] = candidate;
    }

    // Save state for next check
    await _savePreviousState();
  }

  bool _shouldSendNotification(
      NotificationRequest current, NotificationRequest? previous) {
    // Always notify if it's the first time we see this item in problematic state
    if (previous == null) {
      return true;
    }

    // Notify if the state changed and current attempts match max attempts
    if (previous.state != current.state && current.shouldTriggerNotification) {
      return true;
    }

    // Notify if attempts increased and now match max attempts
    if (previous.currentAttempt != current.currentAttempt &&
        current.shouldTriggerNotification) {
      return true;
    }

    return false;
  }

  Future<void> _sendNotification(NotificationRequest notification) async {
    final title = notification.isHost
        ? NotificationConstants.hostNotificationTitle
        : NotificationConstants.serviceNotificationTitle;

    final body = _buildNotificationBody(notification);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      NotificationConstants.statusChannelId,
      NotificationConstants.statusChannelName,
      channelDescription: NotificationConstants.statusChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      _generateNotificationId(notification),
      title,
      body,
      platformChannelSpecifics,
      payload: notification.id,
    );

    debugPrint('[NotificationService] Sent notification: $title - $body');
  }

  String _buildNotificationBody(NotificationRequest notification) {
    if (notification.isHost) {
      return '${notification.name} is ${notification.stateName} (${notification.currentAttempt}/${notification.maxAttempts} attempts)';
    } else {
      return '${notification.displayName} on ${notification.hostName} is ${notification.stateName} (${notification.currentAttempt}/${notification.maxAttempts} attempts)';
    }
  }

  int _generateNotificationId(NotificationRequest notification) {
    return NotificationConstants.baseStatusNotificationId +
        notification.id.hashCode.abs() % 1000;
  }

  Future<void> _showPersistentNotification() async {
    if (!_isAppInBackground) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      NotificationConstants.persistentChannelId,
      NotificationConstants.persistentChannelName,
      channelDescription: NotificationConstants.persistentChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      NotificationConstants.persistentNotificationId,
      NotificationConstants.backgroundServiceTitle,
      NotificationConstants.backgroundServiceMessage,
      platformChannelSpecifics,
    );
  }

  Future<void> _hidePersistentNotification() async {
    await _flutterLocalNotificationsPlugin
        .cancel(NotificationConstants.persistentNotificationId);
  }

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NotificationConstants.notificationsEnabledKey) ?? true;
  }

  Future<void> _loadPreviousState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load previous state
      final stateJson = prefs.getString(NotificationConstants.previousStateKey);
      if (stateJson != null) {
        final Map<String, dynamic> stateMap = jsonDecode(stateJson);
        _previousState = stateMap.map(
            (key, value) => MapEntry(key, NotificationRequest.fromJson(value)));
      }

      // Load notified items
      final notifiedJson =
          prefs.getString(NotificationConstants.notifiedItemsKey);
      if (notifiedJson != null) {
        _notifiedItems = Set<String>.from(jsonDecode(notifiedJson));
      }
    } catch (e) {
      debugPrint('[NotificationService] Error loading previous state: $e');
      _previousState = {};
      _notifiedItems = {};
    }
  }

  Future<void> _savePreviousState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save previous state
      final stateMap =
          _previousState.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(
          NotificationConstants.previousStateKey, jsonEncode(stateMap));

      // Save notified items
      await prefs.setString(NotificationConstants.notifiedItemsKey,
          jsonEncode(_notifiedItems.toList()));
    } catch (e) {
      debugPrint('[NotificationService] Error saving previous state: $e');
    }
  }

  Future<void> _cleanupOldNotifications() async {
    // Remove notifications older than the cooldown period
    final cutoffTime =
        DateTime.now().subtract(NotificationConstants.notificationCooldown);

    _notifiedItems.removeWhere((id) {
      final notification = _previousState[id];
      return notification != null &&
          notification.timestamp.isBefore(cutoffTime);
    });

    _previousState.removeWhere((id, notification) {
      return notification.timestamp.isBefore(cutoffTime);
    });
  }

  /// Public method to request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final bool? granted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }

  /// Public method to enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationConstants.notificationsEnabledKey, enabled);

    if (!enabled) {
      await stopMonitoring();
    } else if (_isInitialized) {
      await startMonitoring();
    }
  }

  /// Public method to test notifications
  Future<void> sendTestNotification() async {
    final testNotification = NotificationRequest(
      id: 'test_notification',
      type: 'service',
      name: 'Test Service',
      hostName: 'Test Host',
      serviceDescription: 'Test Service',
      state: 2, // Critical
      currentAttempt: 3,
      maxAttempts: 3,
      pluginOutput: 'This is a test notification',
      timestamp: DateTime.now(),
    );

    await _sendNotification(testNotification);
  }
}
