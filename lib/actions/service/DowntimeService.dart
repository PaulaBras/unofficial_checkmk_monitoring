import 'package:flutter/material.dart';

import '../../models/downtime.dart';
import '../../services/downtime_service.dart';
import '../../widgets/downtime_form.dart';
import '../../widgets/common_dialogs.dart';
import '../../utils/downtime_constants.dart';

/// Widget for scheduling service downtime
class DowntimeServiceWidget extends StatefulWidget {
  final String hostName;
  final String serviceDescription;

  const DowntimeServiceWidget({
    Key? key,
    required this.hostName,
    required this.serviceDescription,
  }) : super(key: key);

  @override
  State<DowntimeServiceWidget> createState() => _DowntimeServiceWidgetState();
}

class _DowntimeServiceWidgetState extends State<DowntimeServiceWidget> {
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
          DowntimeConstants.serviceSuccessMessage,
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
        title: const Text('Schedule Service Downtime'),
      ),
      body: DowntimeForm(
        hostName: widget.hostName,
        serviceDescription: widget.serviceDescription,
        onSubmit: _handleDowntimeSubmission,
      ),
    );
  }
}
