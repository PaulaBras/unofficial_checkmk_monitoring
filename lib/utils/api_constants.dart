class ApiConstants {
  // Base API paths
  static const String hostsEndpoint = 'domain-types/host/collections/all';
  static const String servicesEndpoint = 'domain-types/service/collections/all';

  // Host states
  static const Map<int, String> hostStates = {
    0: 'OK',
    1: 'Down',
    2: 'Unreachable',
  };

  // Service states
  static const Map<int, String> serviceStates = {
    0: 'OK',
    1: 'Warning',
    2: 'Critical',
    3: 'Unknown',
  };

  // Colors for states
  static const Map<String, String> stateColors = {
    'OK': '#28a745',
    'Warning': '#ffc107',
    'Critical': '#dc3545',
    'Down': '#dc3545',
    'Unreachable': '#6c757d',
    'Unknown': '#6c757d',
  };
}
