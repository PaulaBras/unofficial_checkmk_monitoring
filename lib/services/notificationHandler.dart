import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final StreamController<ReceivedNotification> didReceiveLocalNotificationStream = StreamController<ReceivedNotification>.broadcast();

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

const MethodChannel platform = MethodChannel('checkmk/ptp_4_monitoring_app');

const String portName = 'notification_send_port';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

class NotificationHandler {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _permissionGranted = false;

  static Future<bool> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        // Use platform channel for Android permission request
        final bool? granted = await platform.invokeMethod('requestNotificationPermission');
        _permissionGranted = granted ?? false;
        return _permissionGranted;
      } else if (Platform.isIOS) {
        // For iOS, use the existing method
        final result = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        _permissionGranted = result ?? false;
        return _permissionGranted;
      }
      return true; // Default to true for other platforms
    } catch (e) {
      print('Error requesting notification permission: $e');
      _permissionGranted = false;
      return false;
    }
  }

  static Future<void> initializeNotifications() async {
    // Set up a listener for permission results
    platform.setMethodCallHandler((call) async {
      if (call.method == 'notificationPermissionResult') {
        _permissionGranted = call.arguments as bool;
      }
    });

    // Request notification permissions first
    await requestNotificationPermission();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'checkmk_notification_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('id_1', 'Open'),
          ],
        )
      ],
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        selectNotificationStream.add(notificationResponse.payload);
      },
    );
  }

  static Future<void> showTestNotification() async {
    // Ensure permissions are granted
    bool permissionGranted = await requestNotificationPermission();
    
    if (!permissionGranted) {
      print('Notification permission not granted');
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'checkmk_test_channel',
      'Checkmk Test Notifications',
      channelDescription: 'Test notifications for Checkmk Monitoring App',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'checkmk_notification_category',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Checkmk Monitoring App',
      'This is a test notification to verify your notification settings',
      notificationDetails,
      payload: 'test_notification',
    );
  }

  // Method to send a custom notification
  static Future<void> showNotification({
    required String title, 
    required String body, 
    String? payload
  }) async {
    // Ensure permissions are granted
    bool permissionGranted = await requestNotificationPermission();
    
    if (!permissionGranted) {
      print('Notification permission not granted');
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'checkmk_main_channel',
      'Checkmk Notifications',
      channelDescription: 'Notifications for Checkmk Monitoring App',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'checkmk_notification_category',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
