import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

class AcknowledgeHostForm extends StatefulWidget {
  final dynamic service;

  AcknowledgeHostForm({required this.service});

  @override
  _AcknowledgeHostFormState createState() => _AcknowledgeHostFormState();
}

class _AcknowledgeHostFormState extends State<AcknowledgeHostForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _hostNameController = TextEditingController();
  bool _sticky = true;
  bool _persistent = false;
  bool _notify = true;

  @override
  void initState() {
    super.initState();
    print(widget.service);
    _commentController.text = 'ack';
    _hostNameController.text = widget.service;
  }

  Future<void> acknowledgeHost() async {
    var api = ApiRequest();
    var data = await api.Request(
      'domain-types/acknowledge/collections/host',
      method: 'POST',
      body: {
        "acknowledge_type": "host",
        "sticky": _sticky,
        "persistent": _persistent,
        "notify": _notify,
        "comment": _commentController.text,
        "host_name": _hostNameController.text
      },
    );

    if (data == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Host acknowledged successfully'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } else {
      print("Failed to acknowledge service");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acknowledge Host'),
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
              CheckboxListTile(
                title: Text('Sticky'),
                value: _sticky,
                onChanged: (bool? value) {
                  setState(() {
                    _sticky = value ?? true;
                  });
                },
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
              CheckboxListTile(
                title: Text('Notify'),
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
        onPressed: () {
          if (_formKey.currentState != null &&
              _formKey.currentState!.validate()) {
            acknowledgeHost();
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
