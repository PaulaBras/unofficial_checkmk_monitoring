import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => test());
    //_timer = Timer.periodic(Duration(seconds: 5), (timer) => _checkServices());
  }

  void test() {
    print('Testing notification service');
    notificationServiceCheck.testNotification();
  }

  Future<void> _checkServices() async {
    notificationServiceCheck.testNotification();
    await notificationServiceCheck.checkServices();
  }

  void stop() {
    _timer?.cancel();
  }
}
