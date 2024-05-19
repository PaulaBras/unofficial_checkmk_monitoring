import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifyServiceCheck.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  Timer? _timer;
  Map<String, dynamic> _cache;
  late NotificationServiceCheck notificationServiceCheck;

  NotificationService(this.flutterLocalNotificationsPlugin) : _cache = {} {
    notificationServiceCheck = NotificationServiceCheck(_cache);
  }

  void start() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => _checkServices());
  }

  void test() {
    print('Testing notification service');
    notificationServiceCheck.testNotification();
  }

  Future<void> _checkServices() async {
    try {
      print('Check notification service');
      await notificationServiceCheck.checkServices();
    } catch (e) {
      _timer?.cancel();
      await sendNotification(
        'Error',
        'An error occurred while checking services: ${e.toString()}',
      );
    }
  }

  void stop() {
    _timer?.cancel();
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
