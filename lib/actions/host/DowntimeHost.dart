import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

import '../../services/secureStorage.dart';

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

    if (data == true) {
      print("Downtime created successfully");
    } else {
      print("Failed to create downtime");
    }
  }
}

class DowntimeHostWidget extends StatefulWidget {
  final String hostName;

  DowntimeHostWidget({required this.hostName});

  @override
  _DowntimeHostWidgetState createState() => _DowntimeHostWidgetState();
}

class _DowntimeHostWidgetState extends State<DowntimeHostWidget> {
  final _formKey = GlobalKey<FormState>();
  final _hostNameController = TextEditingController();
  Downtime? _downtime;
  DateTime? _startTime;
  DateTime? _endTime;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  var secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _hostNameController.text = widget.hostName;
    _loadDateFormatAndLocale();
    _downtime = Downtime(
      startTime: _startTime.toString(),
      endTime: _endTime.toString(),
      comment: '',
      downtimeType: 'host',
      hostName: _hostNameController.text,
    );
  }

  void _loadDateFormatAndLocale() async {
    _dateFormat =
        await secureStorage.readSecureData('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = await secureStorage.readSecureData('locale') ?? 'de_DE';
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
                    : 'Start Time: ${DateFormat(_dateFormat, _locale).format(_startTime!)}'),
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
                    : 'End Time: ${DateFormat(_dateFormat, _locale).format(_endTime!)}'),
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
