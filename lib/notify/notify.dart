import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService() {
    final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // Use the app icon as the default image
    //final initializationSettingsIOS = IOSInitializationSettings();
    final initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String header, String footer, String payload) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'CheckMK App',
      'Test Notification',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    //const iOSPlatformChannelSpecifics = IOSNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      header,
      footer,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}