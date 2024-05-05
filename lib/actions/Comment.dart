import '../../services/apiRequest.dart';
import 'package:flutter/material.dart';

class CommentServiceWidget extends StatefulWidget {
  final String hostName;

  CommentServiceWidget({required this.hostName});

  @override
  _CommentServiceWidgetState createState() => _CommentServiceWidgetState();
}

class _CommentServiceWidgetState extends State<CommentServiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _hostNameController = TextEditingController();
  bool _persistent = false;
  String _commentType = 'host';

  @override
  void initState() {
    super.initState();
    _hostNameController.text = widget.hostName;
  }

  Future<void> _addComment() async {
    var api = ApiRequest();
    var data = await api.Request(
      'domain-types/comment/collections/host',
      method: 'POST',
      body: {
        "comment": _commentController.text,
        "persistent": _persistent,
        "comment_type": _commentType,
        "host_name": _hostNameController.text,
      },
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (data['result_code'] == 0) {
      print("Comment added successfully");
    } else {
      print("Failed to add comment");
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
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Comment'),
            ),
            TextFormField(
              controller: _hostNameController,
              decoration: InputDecoration(labelText: 'Host Name'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _addComment();
          }
        },
        tooltip: 'Submit',
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}