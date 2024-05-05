import '../../services/apiRequest.dart';
import 'package:flutter/material.dart';

class Downtime {
  String startTime;
  String endTime;
  final String recur;
  final int duration;
  String comment;
  String downtimeType;
  String hostName;

  Downtime({
    required this.startTime,
    required this.endTime,
    this.recur = "fixed",
    this.duration = 0,
    required this.comment,
    required this.downtimeType,
    required this.hostName,
  });

  Future<void> createDowntime() async {
    var api = ApiRequest();
    var data = await api.Request(
      'domain-types/downtime/collections/host',
      method: 'POST',
      body: {
        "start_time": startTime,
        "end_time": endTime,
        "recur": recur,
        "duration": duration,
        "comment": comment,
        "downtime_type": downtimeType,
        "host_name": hostName,
      },
    );

    if (data['result_code'] == 0) {
      print("Downtime created successfully");
    } else {
      print("Failed to create downtime");
    }
  }
}

class DowntimeServiceWidget extends StatefulWidget {
  final String hostName;

  DowntimeServiceWidget({required this.hostName});

  @override
  _DowntimeServiceWidgetState createState() => _DowntimeServiceWidgetState();
}

class _DowntimeServiceWidgetState extends State<DowntimeServiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _hostNameController = TextEditingController();
  Downtime? _downtime;

  @override
  void initState() {
    super.initState();
    _hostNameController.text = widget.hostName;
    _downtime = Downtime(
      startTime: '',
      endTime: '',
      comment: '',
      downtimeType: '',
      hostName: _hostNameController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downtime Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Start Time'),
              onSaved: (value) {
                _downtime?.startTime = value ?? '';
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'End Time'),
              onSaved: (value) {
                _downtime?.endTime = value ?? '';
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Comment'),
              onSaved: (value) {
                _downtime?.comment = value ?? '';
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Downtime Type'),
              onSaved: (value) {
                _downtime?.downtimeType = value ?? '';
              },
            ),
            TextFormField(
              controller: _hostNameController,
              decoration: InputDecoration(labelText: 'Host Name'),
              enabled: false,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            _downtime?.createDowntime();
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