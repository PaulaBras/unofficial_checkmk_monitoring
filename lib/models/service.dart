/// A model representing a service in the CheckMK monitoring system.
class Service {
  final String hostName;
  final String description;
  final int state;
  final int acknowledged;
  final int currentAttempt;
  final int maxCheckAttempts;
  final int lastCheck;
  final int lastTimeOk;
  final String pluginOutput;

  /// Creates a new Service instance.
  Service({
    required this.hostName,
    required this.description,
    required this.state,
    required this.acknowledged,
    required this.currentAttempt,
    required this.maxCheckAttempts,
    required this.lastCheck,
    required this.lastTimeOk,
    required this.pluginOutput,
  });

  /// Creates a Service instance from a JSON map.
  factory Service.fromJson(Map<String, dynamic> json) {
    final extensions = json['extensions'] as Map<String, dynamic>;
    
    return Service(
      hostName: extensions['host_name'] as String,
      description: extensions['description'] as String,
      state: extensions['state'] as int,
      acknowledged: extensions['acknowledged'] as int,
      currentAttempt: extensions['current_attempt'] as int,
      maxCheckAttempts: extensions['max_check_attempts'] as int,
      lastCheck: extensions['last_check'] as int,
      lastTimeOk: extensions['last_time_ok'] as int,
      pluginOutput: extensions['plugin_output'] as String,
    );
  }

  /// Converts this Service instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'extensions': {
        'host_name': hostName,
        'description': description,
        'state': state,
        'acknowledged': acknowledged,
        'current_attempt': currentAttempt,
        'max_check_attempts': maxCheckAttempts,
        'last_check': lastCheck,
        'last_time_ok': lastTimeOk,
        'plugin_output': pluginOutput,
      },
    };
  }

  /// Returns a string representation of the service state.
  String get stateText {
    switch (state) {
      case 0:
        return 'OK';
      case 1:
        return 'WARNING';
      case 2:
        return 'CRITICAL';
      case 3:
        return 'UNKNOWN';
      default:
        return 'UNDEFINED';
    }
  }

  /// Returns true if the service is acknowledged.
  bool get isAcknowledged => acknowledged == 1;
}
