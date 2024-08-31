import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/apiRequest.dart';

class Downtime {
  String startTime;
  String endTime;
  String recur;
  int duration;
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

  DowntimeServiceWidget({required this.hostName, required this.serviceDescription});

  @override
  _DowntimeServiceWidgetState createState() => _DowntimeServiceWidgetState();
}

class _DowntimeServiceWidgetState extends State<DowntimeServiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _hostNameController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '0');
  Downtime? _downtime;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now();
  String _recur = 'fixed';
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';

  @override
  void initState() {
    super.initState();
    _hostNameController.text = widget.hostName;
    _serviceDescriptionController.text = widget.serviceDescription;
    _loadDateFormatAndLocale();
    _downtime = Downtime(
      startTime: DateFormat(_dateFormat, _locale).format(_startTime),
      endTime: DateFormat(_dateFormat, _locale).format(_endTime),
      comment: '',
      downtimeType: 'service',
      serviceDescription: _serviceDescriptionController.text,
      hostName: _hostNameController.text,
    );
  }

  void _loadDateFormatAndLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
      _locale = prefs.getString('locale') ?? 'de_DE';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downtime Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_startTime == null ? 'Select Start Time' : 'Start Time: ${DateFormat(_dateFormat, _locale).format(_startTime!)}'),
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('en', 'GB'),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
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
                  Text(_endTime == null ? 'Select End Time' : 'End Time: ${DateFormat(_dateFormat, _locale).format(_endTime!)}'),
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('en', 'GB'),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
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
              DropdownButtonFormField<String>(
                value: _recur,
                decoration: InputDecoration(labelText: 'Recur'),
                items: ['fixed', 'hour', 'day', 'week', 'second_week', 'fourth_week', 'weekday_start', 'weekday_end', 'day_of_month'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _recur = newValue!;
                  });
                },
                onSaved: (newValue) {
                  _downtime?.recur = newValue!;
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(labelText: 'Duration (minutes)'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _downtime?.duration = int.tryParse(value ?? '0') ?? 0;
                },
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
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
