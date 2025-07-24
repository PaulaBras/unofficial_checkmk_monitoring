import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../../services/comment_service.dart';
import '../../widgets/comment_form.dart';
import '../../widgets/common_dialogs.dart';
import '../../utils/comment_constants.dart';

/// Widget for adding comments to hosts or services
class CommentServiceWidget extends StatefulWidget {
  final String hostName;
  final String? serviceDescription;

  const CommentServiceWidget({
    Key? key,
    required this.hostName,
    this.serviceDescription,
  }) : super(key: key);

  @override
  State<CommentServiceWidget> createState() => _CommentServiceWidgetState();
}

class _CommentServiceWidgetState extends State<CommentServiceWidget> {
  late final CommentService _commentService;

  @override
  void initState() {
    super.initState();
    _commentService = CommentService();
  }

  Future<void> _handleCommentSubmission(CommentRequest request) async {
    LoadingDialog.show(context, message: CommentConstants.submitLoadingMessage);

    try {
      final success = await _commentService.addComment(request);

      LoadingDialog.hide(context);

      if (success) {
        SnackBarHelper.showSuccess(context, CommentConstants.successMessage);
        Navigator.of(context).pop(true);
      } else {
        SnackBarHelper.showError(context, CommentConstants.failureMessage);
      }
    } catch (e) {
      LoadingDialog.hide(context);
      SnackBarHelper.showError(context, 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceDescription != null
            ? 'Add Service Comment'
            : 'Add Host Comment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(CommentConstants.defaultPadding),
        child: CommentForm(
          hostName: widget.hostName,
          serviceDescription: widget.serviceDescription,
          onSubmit: _handleCommentSubmission,
        ),
      ),
    );
  }
}
