import 'package:flutter/material.dart';

import '../../models/acknowledge.dart';
import '../../services/acknowledge_service.dart';
import '../../widgets/acknowledge_form.dart';
import '../../widgets/common_dialogs.dart';
import '../../utils/acknowledge_constants.dart';

/// Widget for acknowledging services
class AcknowledgeServiceForm extends StatefulWidget {
  final dynamic service;

  const AcknowledgeServiceForm({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<AcknowledgeServiceForm> createState() => _AcknowledgeServiceFormState();
}

class _AcknowledgeServiceFormState extends State<AcknowledgeServiceForm> {
  late final AcknowledgeService _acknowledgeService;
  late final String _hostName;
  late final String _serviceDescription;

  @override
  void initState() {
    super.initState();
    _acknowledgeService = AcknowledgeService();
    _hostName = widget.service['extensions']['host_name'] ?? '';
    _serviceDescription = widget.service['extensions']['description'] ?? '';
  }

  Future<void> _handleAcknowledgeSubmission(AcknowledgeRequest request) async {
    LoadingDialog.show(context,
        message: AcknowledgeConstants.submitLoadingMessage);

    try {
      final success = await _acknowledgeService.acknowledge(request);

      LoadingDialog.hide(context);

      if (success) {
        SnackBarHelper.showSuccess(
            context, AcknowledgeConstants.serviceSuccessMessage);
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
        title: const Text('Acknowledge Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AcknowledgeConstants.defaultPadding),
        child: AcknowledgeForm(
          hostName: _hostName,
          serviceDescription: _serviceDescription,
          onSubmit: _handleAcknowledgeSubmission,
        ),
      ),
    );
  }
}
