import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../../services/secureStorage.dart';
import 'AreNotificationsActive.dart';

class NotificationSchedulePage extends StatefulWidget {
  @override
  _NotificationSchedulePageState createState() =>
      _NotificationSchedulePageState();
}

class _NotificationSchedulePageState extends State<NotificationSchedulePage> {
  TimeOfDay _workingHoursStart = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workingHoursEnd = TimeOfDay(hour: 17, minute: 0);
  bool _notifyDuringWorkingHours = true;
  bool _notifyDuringOffHours = false;
  List<bool> _selectedDays = List<bool>.filled(7, false);
  String _selectedTimeZone = 'Europe/Berlin';
  String _locale = 'de_DE';
  String _dateFormat = 'dd.MM.yyyy, HH:mm';

  AreNotificationsActive notifier = AreNotificationsActive();

  var secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      _selectedDays[i] = true;
    }
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _selectedTimeZone = await secureStorage.readSecureData('timeZone') ?? 'UTC';
    _dateFormat =
        await secureStorage.readSecureData('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = await secureStorage.readSecureData('locale') ?? 'de_DE';

    final startHour = int.parse(
        await secureStorage.readSecureData('workingHoursStartHour') ?? '8');
    final startMinute = int.parse(
        await secureStorage.readSecureData('workingHoursStartMinute') ?? '0');
    _workingHoursStart = TimeOfDay(hour: startHour, minute: startMinute);

    final endHour = int.parse(
        await secureStorage.readSecureData('workingHoursEndHour') ?? '18');
    final endMinute = int.parse(
        await secureStorage.readSecureData('workingHoursEndMinute') ?? '0');
    _workingHoursEnd = TimeOfDay(hour: endHour, minute: endMinute);

    _notifyDuringWorkingHours =
        (await secureStorage.readSecureData('notifyDuringWorkingHours'))
                    ?.toLowerCase() ==
                'true' ??
            true;
    _notifyDuringOffHours =
        (await secureStorage.readSecureData('notifyDuringOffHours'))
                    ?.toLowerCase() ==
                'true' ??
            false;

    for (int i = 0; i < 7; i++) {
      _selectedDays[i] = (await secureStorage.readSecureData('selectedDay$i'))
                  ?.toLowerCase() ==
              'true' ??
          (i < 5);
    }

    setState(() {});
  }

  Future<void> _saveSettings() async {
    await secureStorage.writeSecureData('timeZone', _selectedTimeZone);

    await secureStorage.writeSecureData(
        'workingHoursStartHour', _workingHoursStart.hour.toString());
    await secureStorage.writeSecureData(
        'workingHoursStartMinute', _workingHoursStart.minute.toString());
    await secureStorage.writeSecureData(
        'workingHoursEndHour', _workingHoursEnd.hour.toString());
    await secureStorage.writeSecureData(
        'workingHoursEndMinute', _workingHoursEnd.minute.toString());
    await secureStorage.writeSecureData(
        'notifyDuringWorkingHours', _notifyDuringWorkingHours.toString());
    await secureStorage.writeSecureData(
        'notifyDuringOffHours', _notifyDuringOffHours.toString());

    for (int i = 0; i < 7; i++) {
      await secureStorage.writeSecureData(
          'selectedDay$i', _selectedDays[i].toString());
    }

    // Show a SnackBar to indicate that the settings have been saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings have been saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, String> weekdays = {
      0: 'Mon',
      1: 'Tue',
      2: 'Wed',
      3: 'Thu',
      4: 'Fri',
      5: 'Sat',
      6: 'Sun',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Schedule'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Working hours start'),
            subtitle: Text(_formatTimeOfDay(_workingHoursStart)),
            onTap: () async {
              await _pickWorkingHoursStart();
              _saveSettings();
            },
          ),
          ListTile(
            title: Text('Working hours end'),
            subtitle: Text(_formatTimeOfDay(_workingHoursEnd)),
            onTap: () async {
              await _pickWorkingHoursEnd();
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: Text('Notify during working hours'),
            value: _notifyDuringWorkingHours,
            onChanged: (bool value) {
              setState(() {
                _notifyDuringWorkingHours = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: Text('Notify during off hours'),
            value: _notifyDuringOffHours,
            onChanged: (bool value) {
              setState(() {
                _notifyDuringOffHours = value;
              });
              _saveSettings();
            },
          ),
          ListTile(
            title: Text('Time Zone'),
            trailing: FutureBuilder<List<DropdownMenuItem<String>>>(
              future: _getTimeZones(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else {
                  return DropdownButton<String>(
                    value: _selectedTimeZone,
                    onChanged: (String? newValue) {
                      setState(() {
                        if (newValue != null) {
                          _selectedTimeZone = newValue;
                        }
                      });
                      _saveSettings();
                    },
                    items: snapshot.data,
                  );
                }
              },
            ),
          ),
          // Add a divider to separate the working hours settings from the days to notify settings
          Divider(),
          ListTile(
            title: Text('Select working days'),
          ),
          ...weekdays.entries
              .map((entry) => CheckboxListTile(
                    title: Text(entry.value),
                    value: _selectedDays[entry.key],
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedDays[entry.key] = value ?? false;
                      });
                      _saveSettings();
                    },
                  ))
              .toList(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<bool>(
            future: notifier.areNotificationsActive(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                return Row(
                  children: [
                    Icon(
                      (snapshot.data ?? false)
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color:
                          (snapshot.data ?? false) ? Colors.green : Colors.red,
                    ),
                    SizedBox(
                        width:
                            8.0), // Add some spacing between the icon and the text
                    Text(
                      (snapshot.data ?? false)
                          ? 'Notifications are currently running'
                          : 'Notifications are currently off',
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat('HH:mm', _locale);
    return format.format(dt);
  }

  Future<List<DropdownMenuItem<String>>> _getTimeZones() async {
    return timezone.timeZoneDatabase.locations.keys
        .map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  Future<void> _pickWorkingHoursStart() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workingHoursStart,
    );
    if (picked != null) {
      setState(() {
        _workingHoursStart = picked;
      });
    }
  }

  Future<void> _pickWorkingHoursEnd() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workingHoursEnd,
    );
    if (picked != null) {
      setState(() {
        _workingHoursEnd = picked;
      });
    }
  }
}
