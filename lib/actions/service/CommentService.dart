import 'package:flutter/material.dart';

import '/services/apiRequest.dart';

class CommentServiceWidget extends StatefulWidget {
  final String hostName;
  final String? serviceDescription; // Add optional service description

  CommentServiceWidget({required this.hostName, this.serviceDescription});

  @override
  _CommentServiceWidgetState createState() => _CommentServiceWidgetState();
}

class _CommentServiceWidgetState extends State<CommentServiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  bool _persistent = false;
  String _commentType = 'host';
  bool _isServiceComment = false;

  @override
  void initState() {
    super.initState();
    _hostNameController.text = widget.hostName;

    // Check if this is a service comment
    if (widget.serviceDescription != null) {
      _isServiceComment = true;
      _commentType = 'service';
      _serviceDescriptionController.text = widget.serviceDescription!;
    }
  }

  Future<void> _addComment() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Submitting comment..."),
            ],
          ),
        );
      },
    );

    try {
      var api = ApiRequest();

      // Determine the endpoint and body based on comment type
      String endpoint;
      Map<String, dynamic> body;

      if (_isServiceComment) {
        endpoint = 'domain-types/comment/collections/service';
        body = {
          "comment": _commentController.text,
          "persistent": _persistent,
          "comment_type": _commentType,
          "host_name": _hostNameController.text,
          "service_description": _serviceDescriptionController.text,
        };
      } else {
        endpoint = 'domain-types/comment/collections/host';
        body = {
          "comment": _commentController.text,
          "persistent": _persistent,
          "comment_type": _commentType,
          "host_name": _hostNameController.text,
        };
      }

      var data = await api.Request(
        endpoint,
        method: 'POST',
        body: body,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (data == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment added successfully'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        // Failed to comment service
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment. Please try again.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: Duration(seconds: 3),
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
            children: <Widget>[
              TextFormField(
                controller: _commentController,
                decoration: InputDecoration(labelText: 'Comment'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a comment';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _hostNameController,
                decoration: InputDecoration(labelText: 'Host Name'),
                enabled: false,
              ),
              if (_isServiceComment)
                TextFormField(
                  controller: _serviceDescriptionController,
                  decoration: InputDecoration(labelText: 'Service Description'),
                  enabled: false,
                ),
              CheckboxListTile(
                title: Text('Persistent'),
                value: _persistent,
                onChanged: (bool? value) {
                  setState(() {
                    _persistent = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState != null &&
              _formKey.currentState!.validate()) {
            _addComment();
          }
        },
        tooltip: 'Submit',
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
