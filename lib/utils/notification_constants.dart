class NotificationConstants {
  // Check intervals (in seconds)
  static const int foregroundCheckInterval = 60; // 1 minute
  static const int backgroundCheckInterval = 60; // 1 minute (as requested)
  static const int batteryOptimizedInterval =
      120; // 2 minutes when battery optimized
  static const int lowBatteryInterval = 300; // 5 minutes when battery is low

  // Notification channels
  static const String statusChannelId = 'checkmk_status_channel';
  static const String statusChannelName = 'Status Notifications';
  static const String statusChannelDescription =
      'Notifications when services/hosts reach max attempts';

  static const String persistentChannelId = 'checkmk_persistent_channel';
  static const String persistentChannelName = 'Background Service';
  static const String persistentChannelDescription =
      'Shows when app is monitoring in background';

  // State mappings
  static const Map<int, String> hostStateNames = {
    0: 'UP',
    1: 'DOWN',
    2: 'UNREACHABLE',
  };

  static const Map<int, String> serviceStateNames = {
    0: 'OK',
    1: 'WARNING',
    2: 'CRITICAL',
    3: 'UNKNOWN',
  };

  // States that should trigger notifications
  static const List<int> problematicHostStates = [1, 2]; // Down, Unreachable
  static const List<int> problematicServiceStates = [
    1,
    2,
    3
  ]; // Warning, Critical, Unknown

  // Messages
  static const String hostNotificationTitle = 'Host Alert';
  static const String serviceNotificationTitle = 'Service Alert';
  static const String backgroundServiceTitle = 'CheckMK Monitoring';
  static const String backgroundServiceMessage =
      'Monitoring hosts and services in background';

  // Storage keys
  static const String previousStateKey = 'previous_notification_state';
  static const String notifiedItemsKey = 'notified_items';
  static const String lastCheckKey = 'last_notification_check';

  // Notification IDs
  static const int persistentNotificationId = 9999;
  static const int baseStatusNotificationId = 1000;

  // Settings
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String notificationScheduleKey = 'notifications_schedule';
  static const String hostNotificationsKey = 'host_notifications_enabled';
  static const String serviceNotificationsKey = 'service_notifications_enabled';

  // Battery optimization
  static const int lowBatteryThreshold = 15; // Percentage
  static const Duration notificationCooldown =
      Duration(minutes: 5); // Prevent spam

  // API endpoints for notification checks
  static const String hostsEndpoint = 'domain-types/host/collections/all';
  static const String servicesEndpoint = 'domain-types/service/collections/all';
  static const String hostColumns =
      'state,current_attempt,max_check_attempts,plugin_output';
  static const String serviceColumns =
      'state,current_attempt,max_check_attempts,plugin_output';
}
