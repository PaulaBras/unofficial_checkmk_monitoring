import 'package:flutter/material.dart';

import '../../models/service.dart';
import '../../services/api/api_service.dart';

/// A screen for acknowledging a service.
class AcknowledgeServiceScreen extends StatefulWidget {
  final Service service;

  const AcknowledgeServiceScreen({super.key, required this.service});

  @override
  _AcknowledgeServiceScreenState createState() => _AcknowledgeServiceScreenState();
}

class _AcknowledgeServiceScreenState extends State<AcknowledgeServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _sticky = true;
  bool _persistent = false;
  bool _notify = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController.text = 'ack';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _acknowledgeService() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final apiService = ApiService();
    final success = await apiService.acknowledgeService(
      hostName: widget.service.hostName,
      serviceDescription: widget.service.description,
      comment: _commentController.text,
      sticky: _sticky,
      persistent: _persistent,
      notify: _notify,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service acknowledged successfully'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } else {
      final errorMessage = apiService.getErrorMessage() ?? 'Failed to acknowledge service';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acknowledge Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Service information
              Text(
                'Host: ${widget.service.hostName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Service: ${widget.service.description}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'State: ${widget.service.stateText}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _getStateColor(widget.service.state),
                ),
              ),
              const SizedBox(height: 16),
              
              // Comment field
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a comment';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Options
              CheckboxListTile(
                title: const Text('Sticky'),
                subtitle: const Text('Acknowledgement remains until service returns to OK state'),
                value: _sticky,
                onChanged: (bool? value) {
                  setState(() {
                    _sticky = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Persistent'),
                subtitle: const Text('Acknowledgement survives service restarts'),
                value: _persistent,
                onChanged: (bool? value) {
                  setState(() {
                    _persistent = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Notify'),
                subtitle: const Text('Send notification about this acknowledgement'),
                value: _notify,
                onChanged: (bool? value) {
                  setState(() {
                    _notify = value ?? true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : _acknowledgeService,
        tooltip: 'Submit',
        child: _isSubmitting 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check, color: Colors.white),
        backgroundColor: _isSubmitting 
            ? Colors.grey 
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Color _getStateColor(int state) {
    switch (state) {
      case 0: return Colors.green;
      case 1: return Colors.yellow.shade800;
      case 2: return Colors.red;
      case 3: return Colors.orange;
      default: return Colors.grey;
    }
  }
}
