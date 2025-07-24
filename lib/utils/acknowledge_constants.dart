class AcknowledgeConstants {
  // API Endpoints
  static const String hostAcknowledgeEndpoint =
      'domain-types/acknowledge/collections/host';
  static const String serviceAcknowledgeEndpoint =
      'domain-types/acknowledge/collections/service';

  // Messages
  static const String submitLoadingMessage = 'Acknowledging...';
  static const String hostSuccessMessage = 'Host acknowledged successfully';
  static const String serviceSuccessMessage =
      'Service acknowledged successfully';
  static const String failureMessage =
      'Failed to acknowledge. Please try again.';

  // Form validation
  static const String commentRequiredMessage = 'Please enter a comment';

  // Default values
  static const String defaultComment = 'ack';
  static const bool defaultSticky = true;
  static const bool defaultPersistent = false;
  static const bool defaultNotify = true;

  // UI
  static const double defaultPadding = 16.0;
  static const double formSpacing = 16.0;
  static const double buttonSpacing = 32.0;
  static const int maxCommentLines = 3;
  static const Duration snackBarDuration = Duration(seconds: 3);
}
