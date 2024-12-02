import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';
import '../../services/notificationHandler.dart';
import '../../screens/notify/notify.dart';
import 'AreNotificationsActive.dart';
import 'SetupNotificationSchedule.dart';
import 'ConnectionSettingsWidget.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest();
  late AuthenticationService authService;
  
  bool _notification = true;
  bool _notificationSchedule = false;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  bool _isConnectionSettingsExpanded = false;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    authService = AuthenticationService(secureStorage, apiRequest);
    _loadSettings();
  }

  void _loadSettings() async {
    var notificationSettings = await _notificationService.loadNotificationSettings();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _notification = notificationSettings['enabled'];
      _notificationSchedule = notificationSettings['schedule'] != null && notificationSettings['schedule'] != '';
      _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
      _locale = prefs.getString('locale') ?? 'de_DE';
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('dateFormat', _dateFormat);
    await prefs.setString('locale', _locale);

    await _notificationService.saveNotificationSettings(
      enabled: _notification,
      schedule: _notificationSchedule ? 'default' : '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Notifications Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Notifications', 
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      SwitchListTile(
                        title: Text('Enable Notification'),
                        value: _notification,
                        onChanged: _notificationSchedule
                            ? null
                            : (bool value) async {
                                setState(() {
                                  _notification = value;
                                  _saveSettings();
                                });
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
                        onPressed: _notification ? () {
                          _notificationService.sendNotification(
                            'Test Notification', 
                            'Notifications are working correctly!'
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Test notification sent'), duration: Duration(seconds: 1)),
                          );
                        } : null,
                        child: Text('Send Test Notification'),
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
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),

              // Connection Settings Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Connection', 
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isConnectionSettingsExpanded = !_isConnectionSettingsExpanded;
                          });
                        },
                        child: Text('Manage Connection'),
                      ),
                      if (_isConnectionSettingsExpanded) 
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ConnectionSettingsWidget(
                            onClose: (bool saved) {
                              setState(() {
                                _isConnectionSettingsExpanded = false;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),

              // Localization Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Localization', 
                        style: Theme.of(context).textTheme.headline6,
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
                              _saveSettings();
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
