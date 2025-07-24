import 'package:flutter/material.dart';
import '../utils/ui_constants.dart';
import '../widgets/common_dialogs.dart';

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) _errorMessage = null;
      });
    }
  }

  void setError(String error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  void clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void showErrorSnackBar(String message) {
    if (mounted) {
      SnackBarHelper.showError(context, message);
    }
  }

  void showSuccessSnackBar(String message) {
    if (mounted) {
      SnackBarHelper.showSuccess(context, message);
    }
  }

  Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildErrorWidget(String error, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: UiConstants.defaultSpacing),
            Text(
              'Error',
              style: TextStyle(
                fontSize: UiConstants.titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: UiConstants.smallSpacing),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: UiConstants.bodyFontSize),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: UiConstants.defaultSpacing),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState({
    required String title,
    required String message,
    IconData icon = Icons.inbox,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: UiConstants.defaultSpacing),
            Text(
              title,
              style: TextStyle(
                fontSize: UiConstants.titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: UiConstants.smallSpacing),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: UiConstants.bodyFontSize,
                color: Colors.grey[600],
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: UiConstants.defaultSpacing),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    if (_isLoading) {
      return buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return buildErrorWidget(_errorMessage!, onRetry: onRetry);
    }

    return buildBody();
  }

  Widget buildBody();

  void onRetry() {
    // Override in subclasses
  }

  @override
  Widget build(BuildContext context) {
    return buildContent();
  }
}
