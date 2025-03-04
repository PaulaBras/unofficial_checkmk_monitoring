import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/credentials.dart';
import '../api/api_service.dart';
import '../auth/auth_service.dart';
import '../storage/secure_storage.dart';

/// A service for managing notifications in the application.
class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Timer? _timer;
  Map<String, dynamic> _cache;

  // Notification settings keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationScheduleKey = 'notifications_schedule';

  // Private constructor
  NotificationService._()
      : _cache = {},
        flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin() {
    _initialize();
  }

  // Static instance
  static final NotificationService _instance = NotificationService._();

  // Factory constructor
  factory NotificationService() {
    return _instance;
  }

  /// Initializes the notification service.
  Future<void> _initialize() async {
    final List<DarwinNotificationCategory> darwinNotificationCategories =
        <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        'plainCategory',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('id_1', 'Open'),
        ],
      ),
    ];

    final AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: darwinNotificationCategories,
    );
    
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
      defaultIcon: AssetsLinuxIcon('images/checkmk-icon-green.png'),
    );
    
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Automatically start notifications if enabled (default to true)
    if (await isNotificationsEnabled()) {
      start();
    }
  }

  /// Saves notification settings.
  /// 
  /// [enabled] - Whether notifications are enabled
  /// [schedule] - The notification schedule
  Future<void> saveNotificationSettings({
    bool? enabled,
    String? schedule,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // If enabled is not provided, load the current value
    bool currentEnabled = await isNotificationsEnabled();
    enabled ??= currentEnabled;

    // Save enabled status
    await prefs.setBool(_notificationsEnabledKey, enabled);

    // Save schedule if provided
    if (schedule != null) {
      await prefs.setString(_notificationScheduleKey, schedule);
    }

    // If enabled, start the notification service
    if (enabled) {
      start();
    } else {
      stop();
    }
  }

  /// Loads notification settings.
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'enabled': prefs.getBool(_notificationsEnabledKey) ?? true, // Default to true
      'schedule': prefs.getString(_notificationScheduleKey) ?? '', // Empty schedule by default
    };
  }

  /// Checks if notifications are currently enabled.
  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default to true
  }

  /// Starts the notification service.
  void start() {
    // Only start if not already running
    if (!isRunning()) {
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _checkServices());
    }
  }

  /// Checks if the notification service is running.
  bool isRunning() {
    return _timer != null && _timer!.isActive;
  }

  /// Checks services for changes.
  Future<void> _checkServices() async {
    try {
      // Initialize the AuthService
      final authService = AuthService(SecureStorage(), ApiService());

      // Load the credentials
      Credentials? credentials = await authService.loadCredentials();

      // If credentials are not available, stop the service and return
      if (credentials == null) {
        stop();
        return;
      }

      // Implement service checking logic here
      // This would typically involve checking the status of services
      // and sending notifications for any changes

    } catch (e) {
      stop();
      await sendNotification(
        'Error',
        'An error occurred while checking services: ${e.toString()}',
      );
    }
  }

  /// Checks the timer and restarts it if necessary.
  void checkTimer() {
    if (_timer == null || !_timer!.isActive) {
      start();
    }
  }

  /// Stops the notification service.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Requests notification permissions.
  Future<void> requestNotificationsPermission() async {
    _isAndroidPermissionGranted();
    _requestPermissions();
  }

  /// Checks if Android notification permissions are granted.
  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', granted);
    }
  }

  /// Requests notification permissions.
  Future<void> _requestPermissions() async {
    bool _notificationsEnabled = false;
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      _notificationsEnabled = grantedNotificationPermission ?? false;
      await androidImplementation?.requestExactAlarmsPermission();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }

  /// Sends a notification.
  /// 
  /// [title] - The notification title
  /// [body] - The notification body
  /// [payload] - Optional payload to include with the notification
  Future<void> sendNotification(String title, String body,
      {String? payload}) async {
    // Check if notifications are enabled before sending
    bool isEnabled = await isNotificationsEnabled();
    if (!isEnabled) return;

    // android notification settings
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'service_state_change', 'Service State Change',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    await flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: payload);
  }
}
