import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notificationHandler.dart';
import 'notifyServiceCheck.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Timer? _timer;
  Map<String, dynamic> _cache;
  late NotificationServiceCheck notificationServiceCheck;

  // Private constructor
  NotificationService._()
      : _cache = {},
        flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin() {
    notificationServiceCheck = NotificationServiceCheck(_cache);
    _initialize();
  }

  Future<void> _initialize() async {
    // Define the Darwin notification categories
    final List<DarwinNotificationCategory> darwinNotificationCategories =
        <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        'plainCategory',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('id_1', 'Open'),
        ],
      ),
    ];

    // android notification settings
    final AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    // ios notification settings
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        didReceiveLocalNotificationStream.add(
          ReceivedNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          ),
        );
      },
      notificationCategories: darwinNotificationCategories,
    );
    // linux notification settings
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
      defaultIcon: AssetsLinuxIcon('images/checkmk-icon-green.png'),
    );
    // initialize the settings
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
  }

  // Static instance
  static final NotificationService _instance = NotificationService._();

  // Factory constructor
  factory NotificationService() {
    return _instance;
  }

  void start() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => _checkServices());
  }

  Future<void> _checkServices() async {
    try {
      await notificationServiceCheck.checkServices();
      var errorMessage = notificationServiceCheck.getErrorMessage();
      if (errorMessage != null) {
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
    //_configureDidReceiveLocalNotificationSubject();
    //_configureSelectNotificationSubject();
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
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }

  Future<void> sendNotification(String title, String body,
      {String? payload}) async {
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
