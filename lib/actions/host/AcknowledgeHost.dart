import 'package:flutter/material.dart';

import '../../models/acknowledge.dart';
import '../../services/acknowledge_service.dart';
import '../../widgets/acknowledge_form.dart';
import '../../widgets/common_dialogs.dart';
import '../../utils/acknowledge_constants.dart';

/// Widget for acknowledging hosts
class AcknowledgeHostForm extends StatefulWidget {
  final dynamic service;

  const AcknowledgeHostForm({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<AcknowledgeHostForm> createState() => _AcknowledgeHostFormState();
}

class _AcknowledgeHostFormState extends State<AcknowledgeHostForm> {
  late final AcknowledgeService _acknowledgeService;
  late final String _hostName;

  @override
  void initState() {
    super.initState();
    _acknowledgeService = AcknowledgeService();
    _hostName = widget.service['extensions']['name'] ?? '';
  }

  Future<void> _handleAcknowledgeSubmission(AcknowledgeRequest request) async {
    LoadingDialog.show(context,
        message: AcknowledgeConstants.submitLoadingMessage);

    try {
      final success = await _acknowledgeService.acknowledge(request);

      LoadingDialog.hide(context);

      if (success) {
        SnackBarHelper.showSuccess(
            context, AcknowledgeConstants.hostSuccessMessage);
        Navigator.of(context).pop(true);
      } else {
        SnackBarHelper.showError(context, AcknowledgeConstants.failureMessage);
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
        title: const Text('Acknowledge Host'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AcknowledgeConstants.defaultPadding),
        child: AcknowledgeForm(
          hostName: _hostName,
          onSubmit: _handleAcknowledgeSubmission,
        ),
      ),
    );
  }
}
