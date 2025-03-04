/// A model representing a host in the CheckMK monitoring system.
class Host {
  final String name;
  final String address;
  final int lastCheck;
  final int lastTimeUp;
  final int state;
  final int totalServices;
  final int acknowledged;

  /// Creates a new Host instance.
  Host({
    required this.name,
    required this.address,
    required this.lastCheck,
    required this.lastTimeUp,
    required this.state,
    required this.totalServices,
    required this.acknowledged,
  });

  /// Creates a Host instance from a JSON map.
  factory Host.fromJson(Map<String, dynamic> json) {
    final extensions = json['extensions'] as Map<String, dynamic>;
    
    return Host(
      name: extensions['name'] as String,
      address: extensions['address'] as String,
      lastCheck: extensions['last_check'] as int,
      lastTimeUp: extensions['last_time_up'] as int,
      state: extensions['state'] as int,
      totalServices: extensions['total_services'] as int,
      acknowledged: extensions['acknowledged'] as int,
    );
  }

  /// Converts this Host instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'extensions': {
        'name': name,
        'address': address,
        'last_check': lastCheck,
        'last_time_up': lastTimeUp,
        'state': state,
        'total_services': totalServices,
        'acknowledged': acknowledged,
      },
    };
  }

  /// Returns a string representation of the host state.
  String get stateText {
    switch (state) {
      case 0:
        return 'UP';
      case 1:
        return 'DOWN';
      case 2:
        return 'UNREACHABLE';
      default:
        return 'UNKNOWN';
    }
  }

  /// Returns true if the host is acknowledged.
  bool get isAcknowledged => acknowledged == 1;
}
