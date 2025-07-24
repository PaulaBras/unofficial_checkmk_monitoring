import 'package:flutter/material.dart';

import '../../models/downtime.dart';
import '../../services/downtime_service.dart';
import '../../widgets/downtime_form.dart';
import '../../widgets/common_dialogs.dart';
import '../../utils/downtime_constants.dart';

/// Widget for scheduling host downtime
class DowntimeHostWidget extends StatefulWidget {
  final String hostName;

  const DowntimeHostWidget({
    Key? key,
    required this.hostName,
  }) : super(key: key);

  @override
  State<DowntimeHostWidget> createState() => _DowntimeHostWidgetState();
}

class _DowntimeHostWidgetState extends State<DowntimeHostWidget> {
  late final DowntimeService _downtimeService;

  @override
  void initState() {
    super.initState();
    _downtimeService = DowntimeService();
  }

  Future<void> _handleDowntimeSubmission(DowntimeRequest request) async {
    LoadingDialog.show(context,
        message: DowntimeConstants.submitLoadingMessage);

    try {
      final success = await _downtimeService.createDowntime(request);

      LoadingDialog.hide(context);

      if (success) {
        SnackBarHelper.showSuccess(
          context,
          DowntimeConstants.hostSuccessMessage,
        );
        Navigator.of(context).pop(true);
      } else {
        SnackBarHelper.showError(
          context,
          DowntimeConstants.failureMessage,
        );
      }
    } catch (e) {
      LoadingDialog.hide(context);

      String errorMessage;
      if (e.toString().contains('connection')) {
        errorMessage =
            'Connection error. Please check your network and try again.';
      } else if (e.toString().contains('authentication')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Insufficient permissions to schedule downtime.';
      } else {
        errorMessage = 'Failed to schedule downtime: ${e.toString()}';
      }

      SnackBarHelper.showError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Host Downtime'),
      ),
      body: DowntimeForm(
        hostName: widget.hostName,
        onSubmit: _handleDowntimeSubmission,
      ),
    );
  }
}
