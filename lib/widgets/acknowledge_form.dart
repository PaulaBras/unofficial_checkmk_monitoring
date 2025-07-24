import 'package:flutter/material.dart';
import '../models/acknowledge.dart';
import '../utils/acknowledge_constants.dart';

class AcknowledgeForm extends StatefulWidget {
  final String hostName;
  final String? serviceDescription;
  final Function(AcknowledgeRequest) onSubmit;

  const AcknowledgeForm({
    Key? key,
    required this.hostName,
    required this.onSubmit,
    this.serviceDescription,
  }) : super(key: key);

  @override
  State<AcknowledgeForm> createState() => _AcknowledgeFormState();
}

class _AcknowledgeFormState extends State<AcknowledgeForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _sticky = AcknowledgeConstants.defaultSticky;
  bool _persistent = AcknowledgeConstants.defaultPersistent;
  bool _notify = AcknowledgeConstants.defaultNotify;

  bool get _isServiceAcknowledge => widget.serviceDescription != null;

  @override
  void initState() {
    super.initState();
    _commentController.text = AcknowledgeConstants.defaultComment;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final request = AcknowledgeRequest(
        comment: _commentController.text.trim(),
        sticky: _sticky,
        persistent: _persistent,
        notify: _notify,
        hostName: widget.hostName,
        serviceDescription: widget.serviceDescription,
      );

      widget.onSubmit(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCommentField(),
          const SizedBox(height: AcknowledgeConstants.formSpacing),
          _buildHostNameField(),
          if (_isServiceAcknowledge) ...[
            const SizedBox(height: AcknowledgeConstants.formSpacing),
            _buildServiceDescriptionField(),
          ],
          const SizedBox(height: AcknowledgeConstants.formSpacing),
          _buildOptionsSection(),
          const SizedBox(height: AcknowledgeConstants.buttonSpacing),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
    return TextFormField(
      controller: _commentController,
      decoration: const InputDecoration(
        labelText: 'Comment',
        border: OutlineInputBorder(),
      ),
      maxLines: AcknowledgeConstants.maxCommentLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AcknowledgeConstants.commentRequiredMessage;
        }
        return null;
      },
    );
  }

  Widget _buildHostNameField() {
    return TextFormField(
      initialValue: widget.hostName,
      decoration: const InputDecoration(
        labelText: 'Host Name',
        border: OutlineInputBorder(),
      ),
      enabled: false,
    );
  }

  Widget _buildServiceDescriptionField() {
    return TextFormField(
      initialValue: widget.serviceDescription,
      decoration: const InputDecoration(
        labelText: 'Service Description',
        border: OutlineInputBorder(),
      ),
      enabled: false,
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Options',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            CheckboxListTile(
              title: const Text('Sticky'),
              subtitle:
                  const Text('Acknowledgment remains until state changes'),
              value: _sticky,
              onChanged: (value) {
                setState(() {
                  _sticky = value ?? AcknowledgeConstants.defaultSticky;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Persistent'),
              subtitle: const Text('Acknowledgment persists across restarts'),
              value: _persistent,
              onChanged: (value) {
                setState(() {
                  _persistent = value ?? AcknowledgeConstants.defaultPersistent;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Notify'),
              subtitle:
                  const Text('Send notifications about this acknowledgment'),
              value: _notify,
              onChanged: (value) {
                setState(() {
                  _notify = value ?? AcknowledgeConstants.defaultNotify;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _handleSubmit,
      icon: const Icon(Icons.check),
      label: Text(
          _isServiceAcknowledge ? 'Acknowledge Service' : 'Acknowledge Host'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
