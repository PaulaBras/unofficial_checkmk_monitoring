import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unofficial_checkmk_monitoring/services/apiRequest.dart';
import 'package:unofficial_checkmk_monitoring/services/secureStorage.dart';

import '../../models/credentials.dart';
import '../../services/authService.dart';
import '../../services/notificationHandler.dart';
import 'notifyServiceCheck.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Timer? _timer;
  Map<String, dynamic> _cache;
  late NotificationServiceCheck notificationServiceCheck;

  // Notification settings keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationScheduleKey = 'notifications_schedule';

  // Private constructor
  NotificationService._()
      : _cache = {},
        flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin() {
    notificationServiceCheck = NotificationServiceCheck(_cache);
    _initialize();
  }

  // Save notification settings
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

  // Load notification settings
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'enabled': prefs.getBool(_notificationsEnabledKey) ?? true, // Default to true
      'schedule': prefs.getString(_notificationScheduleKey) ?? '', // Empty schedule by default
    };
  }

  // Check if notifications are currently enabled
  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default to true
  }

  Future<void> _initialize() async {
    // Existing initialization code remains the same...
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
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        if (notificationResponse.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          selectNotificationStream.add(notificationResponse.payload);
        }
      },
    );

    // Automatically start notifications if enabled (default to true)
    if (await isNotificationsEnabled()) {
      start();
    }
  }

  // Static instance
  static final NotificationService _instance = NotificationService._();

  // Factory constructor
  factory NotificationService() {
    return _instance;
  }

  void start() {
    // Only start if not already running
    if (!isRunning()) {
      _timer = Timer.periodic(Duration(seconds: 60), (timer) => _checkServices());
    }
  }

  bool isRunning() {
    return _timer != null && _timer!.isActive;
  }

  Future<void> _checkServices() async {
    try {
      // Initialize the AuthenticationService
      AuthenticationService authService =
          AuthenticationService(SecureStorage(), ApiRequest());

      // Load the credentials
      Credentials? credentials = await authService.loadCredentials();

      // If credentials are available, stop the service and return
      if (credentials != null) {
        stop();
        return;
      }

      await notificationServiceCheck.checkServices();
      var errorMessage = notificationServiceCheck.getErrorMessage();
      if (errorMessage != null) {
        // Handle the error here
      } else {
        // Restart the timer if it was stopped
        if (_timer == null || !_timer!.isActive) {
          start();
        }
      }
    } catch (e) {
      stop();
      await sendNotification(
        'Error',
        'An error occurred while checking services: ${e.toString()}',
      );
    }
  }

  void checkTimer() {
    if (_timer == null || !_timer!.isActive) {
      start();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> requestNotificationsPermission() async {
    _isAndroidPermissionGranted();
    _requestPermissions();
  }

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
