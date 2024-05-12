import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../../services/apiRequest.dart';

class NotificationServiceCheck {
  Map<String, dynamic> _cache;

  NotificationServiceCheck(this._cache);

  Future<void> checkServices() async {
    print('Checking services');
    var api = ApiRequest();
    var data = await api.Request('domain-types/service/collections/all?columns=host_name&columns=description&columns=state&columns=last_check&columns=is_flapping&columns=plugin_output');

    for (var service in data['value']) {
      var id = service['id'];
      var state = service['extensions']['state'];
      var isFlapping = service['extensions']['is_flapping'];

      if (_cache[id] != state && isFlapping == 0) {
        _scheduleNotification(service);
        _cache[id] = state;
      }
    }
  }

  void _scheduleNotification(dynamic service) async {
    var state = service['extensions']['state'];
    var host = service['extensions']['host_name'];
    var description = service['extensions']['description'];
    var pluginOutput = service['extensions']['plugin_output'];

    var stateText = '';
    switch (state) {
      case 0:
        stateText = '[OK]';
        break;
      case 1:
        stateText = '[Warning]';
        break;
      case 2:
        stateText = '[CRITICAL]';
        break;
      case 3:
        stateText = '[Unknown]';
        break;
    }

    var androidPlatformChannelSpecifics = AndroidNotificationDetails('service_state_change', 'Service State Change', importance: Importance.max, priority: Priority.high, showWhen: false);
    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'Service State Change', 'Host: $host, Service: $description, State: $stateText, Output: $pluginOutput', platformChannelSpecifics);
  }
}
