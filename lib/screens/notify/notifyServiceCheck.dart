import '../../main.dart';
import '../../services/apiRequest.dart';

class NotificationServiceCheck {
  Map<String, dynamic> _cache;
  String? _errorMessage;

  NotificationServiceCheck(this._cache);

  Future<void> checkServices() async {
    var api = ApiRequest();
    var data = await api.Request(
        'domain-types/service/collections/all?columns=host_name&columns=description&columns=state&columns=last_check&columns=is_flapping&columns=plugin_output');

    _errorMessage = api.getErrorMessage();
    if (_errorMessage != null) {
      // Handle the error, for example, print the error message
      // Stop the timer
      throw Exception('Failed to make notify network request: $_errorMessage');
    } else {
      if (data != null && data['value'] != null) {
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
    }
  }

  String? getErrorMessage() {
    return _errorMessage;
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

    await notificationService?.sendNotification(
      '$stateText Service State Change',
      'Host: $host, Service: $description, Output: $pluginOutput',
    );
  }
}
