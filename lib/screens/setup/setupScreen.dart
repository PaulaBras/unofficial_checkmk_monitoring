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

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest(); // Create an ApiRequest instance
  late AuthenticationService authService;
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _siteController = TextEditingController();
  bool _ignoreCertificate = false;
  bool _notification = true; // Default to true
  bool _notificationSchedule = false;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  String _protocol = 'https';
  final _formKey = GlobalKey<FormState>();
  Timer? _notificationCheckTask;

  // Notification service instance
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    authService = AuthenticationService(secureStorage, apiRequest);
    _loadSettings();
  }

  void _loadSettings() async {
    // Load server and authentication details
    _protocol = await secureStorage.readSecureData('protocol') ?? '';
    _serverController.text = await secureStorage.readSecureData('server') ?? '';
    _usernameController.text = await secureStorage.readSecureData('username') ?? '';
    _passwordController.text = await secureStorage.readSecureData('password') ?? '';
    _siteController.text = await secureStorage.readSecureData('site') ?? '';
    _ignoreCertificate = (await secureStorage.readSecureData('ignoreCertificate'))?.toLowerCase() == 'true' ?? false;

    // Load notification settings
    var notificationSettings = await _notificationService.loadNotificationSettings();
    setState(() {
      _notification = notificationSettings['enabled'];
      _notificationSchedule = notificationSettings['schedule'] != null && notificationSettings['schedule'] != '';
    });

    // Load other preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = prefs.getString('locale') ?? 'de_DE';
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Save server and authentication details
      await secureStorage.writeSecureData('server', _serverController.text);
      await secureStorage.writeSecureData('username', _usernameController.text);
      await secureStorage.writeSecureData('password', _passwordController.text);
      await secureStorage.writeSecureData('site', _siteController.text);
      await secureStorage.writeSecureData('ignoreCertificate', _ignoreCertificate.toString());
      await secureStorage.writeSecureData('protocol', _protocol);

      // Save notification settings
      await _notificationService.saveNotificationSettings(
        enabled: _notification,
        schedule: _notificationSchedule ? 'default' : '',
      );

      // Save locale and date format preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('dateFormat', _dateFormat);
      await prefs.setString('locale', _locale);

      // Login again
      bool loginSuccessful = await authService.login(
          _usernameController.text, _passwordController.text);
      if (loginSuccessful) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed. Please check your credentials.')),
        );
      }
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: _protocol,
                  items: <String>['http', 'https']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _protocol = newValue!;
                    });
                  },
                ),
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
                  onChanged: _protocol == 'https'
                      ? (bool value) {
                          setState(() {
                            _ignoreCertificate = value;
                          });
                          _saveSettings();
                        }
                      : null,
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
                  onPressed: _notification ? () {
                    // Send a test notification only if notifications are enabled
                    _notificationService.sendNotification(
                      'Test Notification', 
                      'Notifications are working correctly!'
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Test notification sent')),
                    );
                  } : null, // Disable button if notifications are not enabled
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
      ),
    );
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _siteController.dispose();
    super.dispose();
  }
}
