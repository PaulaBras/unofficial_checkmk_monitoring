import 'package:flutter/material.dart';
import '../services/apiRequest.dart';

class AcknowledgeServiceForm extends StatefulWidget {
  final dynamic service;

  AcknowledgeServiceForm({required this.service});

  @override
  _AcknowledgeServiceFormState createState() => _AcknowledgeServiceFormState();
}

class _AcknowledgeServiceFormState extends State<AcknowledgeServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  bool _sticky = true;
  bool _persistent = false;
  bool _notify = true;

  @override
  void initState() {
    super.initState();
    _hostNameController.text = widget.service['extensions']['host_name'];
    _serviceDescriptionController.text = widget.service['extensions']['description'];
  }

  Future<void> acknowledgeService() async {
    var api = ApiRequest();
    var data = await api.Request(
      'domain-types/acknowledge/collections/service',
      method: 'POST',
      body: {
        "acknowledge_type": "service",
        "sticky": _sticky,
        "persistent": _persistent,
        "notify": _notify,
        "comment": _commentController.text,
        "host_name": _hostNameController.text,
        "service_description": _serviceDescriptionController.text
      },
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (data['result_code'] == 0) {
      print("Service acknowledged successfully");
    } else {
      print("Failed to acknowledge service");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acknowledge Service'),
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
              ),
              TextFormField(
                controller: _hostNameController,
                decoration: InputDecoration(labelText: 'Host Name'),
                enabled: false,
              ),
              TextFormField(
                controller: _serviceDescriptionController,
                decoration: InputDecoration(labelText: 'Service Description'),
                enabled: false,
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
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    acknowledgeService();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}