import 'package:intl/intl.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';
import 'package:flutter/material.dart';

class Downtime {
  String startTime;
  String endTime;
  final String recur;
  final int duration;
  String comment;
  String downtimeType;
  String serviceDescription;
  String hostName;

  Downtime({
    required this.startTime,
    required this.endTime,
    this.recur = "fixed",
    this.duration = 0,
    required this.comment,
    required this.downtimeType,
    required this.serviceDescription,
    required this.hostName,
  });

  Future<void> createDowntime() async {
    var api = ApiRequest();
    var data = await api.Request(
      'domain-types/downtime/collections/service',
      method: 'POST',
      body: {
        "start_time": startTime,
        "end_time": endTime,
        "recur": recur,
        "duration": duration,
        "comment": comment,
        "downtime_type": downtimeType,
        "service_descriptions": [serviceDescription],
        "host_name": hostName,
      },
    );

    if (data == true) {
      print("Downtime created successfully");
    } else {
      print("Failed to create downtime");
    }
  }
}

class DowntimeServiceWidget extends StatefulWidget {
  final String hostName;
  final String serviceDescription;

  DowntimeServiceWidget(
      {required this.hostName, required this.serviceDescription});

  @override
  _DowntimeServiceWidgetState createState() => _DowntimeServiceWidgetState();
}

class _DowntimeServiceWidgetState extends State<DowntimeServiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _hostNameController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  Downtime? _downtime;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _hostNameController.text = widget.hostName;
    _serviceDescriptionController.text = widget.serviceDescription;
    _downtime = Downtime(
      startTime: _startTime.toString(),
      endTime: _endTime.toString(),
      comment: '',
      downtimeType: 'service',
      serviceDescription: _serviceDescriptionController.text,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_startTime == null
                    ? 'Select Start Time'
                    : 'Start Time: ${DateFormat('H:m d.M.y').format(_startTime!)}'),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _startTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Text('Select'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_endTime == null
                    ? 'Select End Time'
                    : 'End Time: ${DateFormat('H:m d.M.y').format(_endTime!)}'),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _endTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Text('Select'),
                ),
              ],
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Comment'),
              onSaved: (value) {
                _downtime?.comment = value ?? '';
              },
            ),
            TextFormField(
              controller: _serviceDescriptionController,
              decoration: InputDecoration(labelText: 'Service Description'),
              enabled: false,
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
