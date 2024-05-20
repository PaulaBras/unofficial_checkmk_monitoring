import 'dart:async';

import 'package:flutter/services.dart';

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
