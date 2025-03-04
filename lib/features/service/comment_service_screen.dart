import 'package:flutter/material.dart';

import '../../models/service.dart';
import '../../services/api/api_service.dart';

/// A screen for adding a comment to a service.
class CommentServiceScreen extends StatefulWidget {
  final Service service;

  const CommentServiceScreen({super.key, required this.service});

  @override
  _CommentServiceScreenState createState() => _CommentServiceScreenState();
}

class _CommentServiceScreenState extends State<CommentServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final apiService = ApiService();
    final success = await apiService.commentService(
      hostName: widget.service.hostName,
      serviceDescription: widget.service.description,
      comment: _commentController.text,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } else {
      final errorMessage = apiService.getErrorMessage() ?? 'Failed to add comment';
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
        title: const Text('Add Comment'),
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
                  hintText: 'Enter your comment here',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a comment';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : _addComment,
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
