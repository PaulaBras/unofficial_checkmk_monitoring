import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/secureStorage.dart';
import 'AreNotificationsActive.dart';
import 'SetupNotificationSchedule.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  var secureStorage = SecureStorage();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _siteController = TextEditingController();
  bool _ignoreCertificate = false;
  bool _notification = false;
  bool _notificationSchedule = false;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  final _formKey = GlobalKey<FormState>();
  bool _isNotificationActive = false;
  bool _isNotificationScheduleActive = false;
  Timer? _notificationCheckTask;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startNotificationCheckTask();
  }

  void _loadSettings() async {
    _serverController.text = await secureStorage.readSecureData('server') ?? '';
    _usernameController.text =
        await secureStorage.readSecureData('username') ?? '';
    _passwordController.text =
        await secureStorage.readSecureData('password') ?? '';
    _siteController.text = await secureStorage.readSecureData('site') ?? '';
    _ignoreCertificate =
        (await secureStorage.readSecureData('ignoreCertificate'))
                    ?.toLowerCase() ==
                'true' ??
            false;
    _notification =
        (await secureStorage.readSecureData('notification'))?.toLowerCase() ==
                'true' ??
            false;
    _notification = (await secureStorage.readSecureData('notificationSchedule'))
                ?.toLowerCase() ==
            'true' ??
        false;
    _dateFormat =
        await secureStorage.readSecureData('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = await secureStorage.readSecureData('locale') ?? 'de_DE';
    _isNotificationActive =
        (await secureStorage.readSecureData('notification'))?.toLowerCase() ==
                'true' ??
            false;
    _isNotificationScheduleActive =
        (await secureStorage.readSecureData('notificationSchedule'))
                    ?.toLowerCase() ==
                'true' ??
            false;
    if (_notificationSchedule) {
      var notifier = AreNotificationsActive();
      _notification = await notifier.areNotificationsActive();
    }
    setState(() {});
  }

  void _startNotificationCheckTask() {
    _notificationCheckTask =
        Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_isNotificationActive || _isNotificationScheduleActive) {
        var notifier = AreNotificationsActive();
        _notification = await notifier.areNotificationsActive();
        _saveSettings();
      }
    });
  }

  @override
  void dispose() {
    _notificationCheckTask?.cancel();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await secureStorage.writeSecureData('server', _serverController.text);
      await secureStorage.writeSecureData('username', _usernameController.text);
      await secureStorage.writeSecureData('password', _passwordController.text);
      await secureStorage.writeSecureData('site', _siteController.text);
      await secureStorage.writeSecureData(
          'ignoreCertificate', _ignoreCertificate.toString());
      await secureStorage.writeSecureData(
          'notification', _notification.toString());
      await secureStorage.writeSecureData(
          'notificationSchedule', _notificationSchedule.toString());
      await secureStorage.writeSecureData('dateFormat', _dateFormat);
      await secureStorage.writeSecureData('locale', _locale);
      //Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Setup Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _serverController,
                decoration: InputDecoration(
                  labelText: 'Server',
                ),
                onSaved: (value) => _serverController.text = value!,
              ),
              TextFormField(
                controller: _siteController,
                decoration: InputDecoration(
                  labelText: 'Site',
                ),
                onSaved: (value) => _siteController.text = value!,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                ),
                onSaved: (value) => _usernameController.text = value!,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                onSaved: (value) => _passwordController.text = value!,
              ),
              SwitchListTile(
                title: Text('Ignore Certificate Warnings'),
                value: _ignoreCertificate,
                onChanged: (bool value) {
                  setState(() {
                    _ignoreCertificate = value;
                  });
                  _saveSettings();
                },
              ),
              SwitchListTile(
                title: Text('Enable Notification'),
                value: _notification,
                onChanged: _notificationSchedule
                    ? null
                    : (bool value) async {
                        setState(() {
                          _notification = value;
                        });
                        _saveSettings();
                      },
              ),
              SwitchListTile(
                title: Text('Enable Schedule Notification'),
                value: _notificationSchedule,
                onChanged: (bool value) async {
                  setState(() {
                    _notificationSchedule = value;
                  });
                  var notifier = AreNotificationsActive();
                  _notification = await notifier.areNotificationsActive();
                  _saveSettings();
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationSchedulePage()),
                  );
                },
                child: Text('Setup Notification Schedule'),
              ),
              DropdownButton<String>(
                value: _locale,
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      _dateFormat = newValue == 'de_DE'
                          ? 'dd.MM.yyyy, HH:mm'
                          : 'MM/dd/yyyy, hh:mm a';
                      _locale = newValue;
                    }
                  });
                },
                items: <String>['de_DE', 'en_US']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
