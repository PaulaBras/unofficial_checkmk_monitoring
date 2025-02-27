import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/service.dart';
import '../../services/api/api_service.dart';

/// A screen for scheduling downtime for a service.
class DowntimeServiceScreen extends StatefulWidget {
  final Service service;

  const DowntimeServiceScreen({super.key, required this.service});

  @override
  _DowntimeServiceScreenState createState() => _DowntimeServiceScreenState();
}

class _DowntimeServiceScreenState extends State<DowntimeServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _durationController = TextEditingController(text: '0');
  
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  String _recur = 'fixed';
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDateFormatAndLocale();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _loadDateFormatAndLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
      _locale = prefs.getString('locale') ?? 'de_DE';
    });
  }

  Future<void> _scheduleDowntime() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final apiService = ApiService();
    final success = await apiService.scheduleServiceDowntime(
      hostName: widget.service.hostName,
      serviceDescription: widget.service.description,
      startTime: DateFormat(_dateFormat, _locale).format(_startTime),
      endTime: DateFormat(_dateFormat, _locale).format(_endTime),
      recur: _recur,
      duration: int.tryParse(_durationController.text) ?? 0,
      comment: _commentController.text,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downtime scheduled successfully'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } else {
      final errorMessage = apiService.getErrorMessage() ?? 'Failed to schedule downtime';
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
        title: const Text('Schedule Downtime'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                
                // Time selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Start Time: ${DateFormat(_dateFormat, _locale).format(_startTime)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('en', 'GB'),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_startTime),
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null && mounted) {
                            setState(() {
                              _startTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                              
                              // Ensure end time is after start time
                              if (_endTime.isBefore(_startTime)) {
                                _endTime = _startTime.add(const Duration(hours: 2));
                              }
                            });
                          }
                        }
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'End Time: ${DateFormat(_dateFormat, _locale).format(_endTime)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endTime,
                          firstDate: _startTime,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('en', 'GB'),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_endTime),
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null && mounted) {
                            final newEndTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            
                            if (newEndTime.isAfter(_startTime)) {
                              setState(() {
                                _endTime = newEndTime;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('End time must be after start time'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Recurrence type
                DropdownButtonFormField<String>(
                  value: _recur,
                  decoration: const InputDecoration(
                    labelText: 'Recurrence',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'fixed',
                    'hour',
                    'day',
                    'week',
                    'second_week',
                    'fourth_week',
                    'weekday_start',
                    'weekday_end',
                    'day_of_month'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _recur = newValue ?? 'fixed';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Duration
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                    helperText: 'Only used for flexible downtimes',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Comment
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
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : _scheduleDowntime,
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
