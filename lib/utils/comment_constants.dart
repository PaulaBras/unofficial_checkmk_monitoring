class CommentConstants {
  // API Endpoints
  static const String hostCommentEndpoint =
      'domain-types/comment/collections/host';
  static const String serviceCommentEndpoint =
      'domain-types/comment/collections/service';

  // Messages
  static const String submitLoadingMessage = 'Submitting comment...';
  static const String successMessage = 'Comment added successfully';
  static const String failureMessage =
      'Failed to add comment. Please try again.';

  // Form validation
  static const String commentRequiredMessage = 'Please enter a comment';

  // UI
  static const double defaultPadding = 16.0;
  static const double formSpacing = 16.0;
  static const double buttonSpacing = 32.0;
  static const int maxCommentLines = 3;
  static const Duration snackBarDuration = Duration(seconds: 3);
}
