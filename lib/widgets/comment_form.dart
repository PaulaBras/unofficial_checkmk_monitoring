import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/comment_constants.dart';

class CommentForm extends StatefulWidget {
  final String hostName;
  final String? serviceDescription;
  final Function(CommentRequest) onSubmit;

  const CommentForm({
    Key? key,
    required this.hostName,
    required this.onSubmit,
    this.serviceDescription,
  }) : super(key: key);

  @override
  State<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _persistent = false;

  bool get _isServiceComment => widget.serviceDescription != null;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final request = CommentRequest(
        comment: _commentController.text.trim(),
        persistent: _persistent,
        commentType: _isServiceComment
            ? CommentType.service.value
            : CommentType.host.value,
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
          const SizedBox(height: CommentConstants.formSpacing),
          _buildHostNameField(),
          if (_isServiceComment) ...[
            const SizedBox(height: CommentConstants.formSpacing),
            _buildServiceDescriptionField(),
          ],
          const SizedBox(height: CommentConstants.formSpacing),
          _buildPersistentCheckbox(),
          const SizedBox(height: CommentConstants.buttonSpacing),
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
      maxLines: CommentConstants.maxCommentLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return CommentConstants.commentRequiredMessage;
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

  Widget _buildPersistentCheckbox() {
    return CheckboxListTile(
      title: const Text('Persistent'),
      subtitle: const Text('Comment will persist across restarts'),
      value: _persistent,
      onChanged: (value) {
        setState(() {
          _persistent = value ?? false;
        });
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _handleSubmit,
      icon: const Icon(Icons.check),
      label: const Text('Submit Comment'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
