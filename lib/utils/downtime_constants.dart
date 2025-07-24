class DowntimeConstants {
  // API Endpoints
  static const String hostDowntimeEndpoint =
      'domain-types/downtime/collections/host';
  static const String serviceDowntimeEndpoint =
      'domain-types/downtime/collections/service';

  // Messages
  static const String submitLoadingMessage = 'Creating downtime...';
  static const String hostSuccessMessage = 'Host downtime created successfully';
  static const String serviceSuccessMessage =
      'Service downtime created successfully';
  static const String failureMessage =
      'Failed to create downtime. Please try again.';

  // Form validation
  static const String commentRequiredMessage = 'Please enter a comment';
  static const String startTimeRequiredMessage = 'Please select start time';
  static const String endTimeRequiredMessage = 'Please select end time';
  static const String invalidTimeRangeMessage =
      'End time must be after start time';

  // Default values
  static const String defaultComment = 'Planned maintenance';
  static const String defaultRecur = 'fixed';
  static const int defaultDuration = 0;
  static const String defaultDowntimeType = 'host';

  // Duration options (in hours)
  static const List<int> durationOptions = [1, 2, 4, 8, 12, 24, 48, 72];

  // UI
  static const double defaultPadding = 16.0;
  static const double formSpacing = 16.0;
  static const double buttonSpacing = 32.0;
  static const int maxCommentLines = 3;
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Date/Time
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';
}
