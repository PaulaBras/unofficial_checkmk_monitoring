import 'package:flutter/material.dart';
import '../utils/comment_constants.dart';

class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({
    Key? key,
    this.message = 'Loading...',
  }) : super(key: key);

  static void show(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(message),
        ],
      ),
    );
  }
}

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: CommentConstants.snackBarDuration,
        backgroundColor: Colors.green,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: CommentConstants.snackBarDuration,
        backgroundColor: Colors.red,
      ),
    );
  }
}
