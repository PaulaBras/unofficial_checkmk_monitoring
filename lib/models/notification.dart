import '../utils/notification_constants.dart';
import 'service.dart';

class NotificationRequest {
  final String id;
  final String type; // 'host' or 'service'
  final String name;
  final String hostName;
  final String? serviceDescription;
  final int state;
  final int currentAttempt;
  final int maxAttempts;
  final String pluginOutput;
  final DateTime timestamp;

  const NotificationRequest({
    required this.id,
    required this.type,
    required this.name,
    required this.hostName,
    this.serviceDescription,
    required this.state,
    required this.currentAttempt,
    required this.maxAttempts,
    required this.pluginOutput,
    required this.timestamp,
  });

  bool get isHost => type == 'host';
  bool get isService => type == 'service';
  bool get shouldTriggerNotification =>
      currentAttempt == maxAttempts && isProblematic;

  bool get isProblematic {
    if (isHost) {
      return state == 1 || state == 2; // Down or Unreachable
    } else {
      return state == 1 ||
          state == 2 ||
          state == 3; // Warning, Critical, or Unknown
    }
  }

  String get stateName {
    if (isHost) {
      return NotificationConstants.hostStateNames[state] ?? 'Unknown';
    } else {
      return NotificationConstants.serviceStateNames[state] ?? 'Unknown';
    }
  }

  String get displayName => serviceDescription ?? name;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'hostName': hostName,
      'serviceDescription': serviceDescription,
      'state': state,
      'currentAttempt': currentAttempt,
      'maxAttempts': maxAttempts,
      'pluginOutput': pluginOutput,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory NotificationRequest.fromJson(Map<String, dynamic> json) {
    return NotificationRequest(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      hostName: json['hostName'],
      serviceDescription: json['serviceDescription'],
      state: json['state'],
      currentAttempt: json['currentAttempt'],
      maxAttempts: json['maxAttempts'],
      pluginOutput: json['pluginOutput'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  factory NotificationRequest.fromHost(Map<String, dynamic> hostData) {
    final extensions = hostData['extensions'];
    return NotificationRequest(
      id: 'host_${extensions['name']}',
      type: 'host',
      name: extensions['name'],
      hostName: extensions['name'],
      state: extensions['state'],
      currentAttempt: extensions['current_attempt'] ?? 1,
      maxAttempts: extensions['max_check_attempts'] ?? 3,
      pluginOutput: extensions['plugin_output'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  factory NotificationRequest.fromService(Map<String, dynamic> serviceData) {
    final extensions = serviceData['extensions'];
    return NotificationRequest(
      id: 'service_${extensions['host_name']}_${extensions['description']}',
      type: 'service',
      name: extensions['description'],
      hostName: extensions['host_name'],
      serviceDescription: extensions['description'],
      state: extensions['state'],
      currentAttempt: extensions['current_attempt'] ?? 1,
      maxAttempts: extensions['max_check_attempts'] ?? 3,
      pluginOutput: extensions['plugin_output'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  /// Create NotificationRequest from Service model
  factory NotificationRequest.fromServiceModel(Service service) {
    return NotificationRequest(
      id: 'service_${service.hostName}_${service.description}',
      type: 'service',
      name: service.description,
      hostName: service.hostName,
      serviceDescription: service.description,
      state: service.state,
      currentAttempt: service.currentAttempt,
      maxAttempts: service.maxCheckAttempts,
      pluginOutput: service.pluginOutput,
      timestamp: DateTime.now(),
    );
  }
}

enum NotificationType {
  host('host'),
  service('service');

  const NotificationType(this.value);
  final String value;
}

enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  critical('critical');

  const NotificationPriority(this.value);
  final String value;
}
