import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../../services/apiRequest.dart';

class NotificationServiceCheck {
  Map<String, dynamic> _cache;

  NotificationServiceCheck(this._cache);

  void testNotification() {
    var mockService = {
      'extensions': {'state': 2, 'host_name': 'Test Host', 'description': 'Test Description', 'plugin_output': 'Test Output'}
    };

    _scheduleNotification(mockService);
    print('Test notification scheduled');
  }

  Future<void> checkServices() async {
    print('Checking services');
    var api = ApiRequest();
    var data = await api.Request('domain-types/service/collections/all?columns=host_name&columns=description&columns=state&columns=last_check&columns=is_flapping&columns=plugin_output');

    for (var service in data['value']) {
      var id = service['id'];
      var state = service['extensions']['state'];
      var isFlapping = service['extensions']['is_flapping'];

      // Add the service to the cache regardless of its state
      _cache[id] = state;

      // Only schedule a notification if the state has changed and the service is not flapping
      if (_cache[id] != state && isFlapping == 0) {
        _scheduleNotification(service);
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
    await flutterLocalNotificationsPlugin.show(0, '$stateText Service State Change', 'Host: $host, Service: $description, Output: $pluginOutput', platformChannelSpecifics);
  }
}
