import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';
import '../../services/notificationHandler.dart';
import '../../services/themeNotifier.dart';
import '../myHomePage.dart';
import '../setup/ConnectionSettingsWidget.dart';
import '../setup/AreNotificationsActive.dart';
import '../setup/SetupNotificationSchedule.dart';
import '../user/loginScreen.dart';

class UserScreen extends StatefulWidget {
  final bool fromDrawer;

  const UserScreen({super.key, this.fromDrawer = false});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final SecureStorage _secureStorage = SecureStorage();
  final ApiRequest _apiRequest = ApiRequest();
  late AuthenticationService _authService;
  final CheckmkNotificationService _notificationService = CheckmkNotificationService();
  
  String _startPage = 'Dashboard';
  bool _notification = true;
  bool _notificationSchedule = false;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  bool _isConnectionSettingsExpanded = false;

  // Service state notification settings
  final Map<String, bool> _serviceStateNotifications = {
    'green': true,
    'warning': true,
    'critical': true,
    'unknown': true,
  };

  final Map<String, int> _pageNameToIndex = {
    'Dashboard': 0,
    'Service': 1,
    'Host': 2,
  };

  @override
  void initState() {
    super.initState();
    _authService = AuthenticationService(_secureStorage, _apiRequest);
    final myHomePageLogic = MyHomePageLogic();
    myHomePageLogic.loadStartIndex().then((value) {
      setState(() {
        _startPage = _pageNameToIndex.keys.elementAt(value);
      });
    });
    _loadSettings();
    _loadServiceNotificationSettings();
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

  void _loadServiceNotificationSettings() async {
    for (var state in _serviceStateNotifications.keys) {
      String? savedSetting = await _secureStorage.readSecureData('notify_$state');
      setState(() {
        _serviceStateNotifications[state] = savedSetting?.toLowerCase() != 'false';
      });
    }
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('dateFormat', _dateFormat);
    await prefs.setString('locale', _locale);

    await _notificationService.saveNotificationSettings(
      enabled: _notification,
      schedule: _notificationSchedule ? 'default' : '',
    );

    // Save service state notification settings
    for (var entry in _serviceStateNotifications.entries) {
      await _secureStorage.writeSecureData('notify_${entry.key}', entry.value.toString());
    }
  }

  void _toggleServiceNotification(String state, bool value) async {
    await _secureStorage.writeSecureData('notify_$state', value.toString());
    setState(() {
      _serviceStateNotifications[state] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final myHomePageLogic = MyHomePageLogic();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.fromDrawer) {
              Navigator.pop(context);
            } else {
              myHomePageLogic.navigateToMain();
            }
          },
        ),
      ),
      body: ListView(
        children: <Widget>[
          // User Interface Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'images/icon_topic_user_interface.svg',
                        width: 30,
                        height: 30,
                        colorFilter: ColorFilter.mode(
                            colorScheme.primary, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'User interface',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Dark Theme'),
                  value: themeNotifier.darkTheme,
                  onChanged: (value) {
                    setState(() {
                      themeNotifier.toggleTheme();
                    });
                  },
                ),
                ListTile(
                  title: const Text('Set Start Page'),
                  trailing: DropdownButton<String>(
                    value: _startPage,
                    items: _pageNameToIndex.keys.map((pageName) {
                      return DropdownMenuItem<String>(
                        value: pageName,
                        child: Text(pageName),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _startPage = newValue;
                        });
                        myHomePageLogic.updateStartIndex(_pageNameToIndex[newValue]!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Notifications Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Notifications',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Enable Notification'),
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
                  title: const Text('Enable Schedule Notification'),
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
                
                // Service State Notification Settings
                ExpansionTile(
                  title: const Text('Service State Notifications'),
                  children: _serviceStateNotifications.keys.map((state) {
                    return SwitchListTile(
                      title: Text('Notify on $state state'),
                      value: _serviceStateNotifications[state] ?? true,
                      onChanged: (bool? value) {
                        _toggleServiceNotification(state, value ?? true);
                      },
                    );
                  }).toList(),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _notification ? () {
                      _notificationService.sendNotification(
                        'Test Notification', 
                        'Notifications are working correctly!'
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test notification sent'), duration: Duration(seconds: 1)),
                      );
                    } : null,
                    child: const Text('Send Test Notification'),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationSchedulePage()),
                      );
                    },
                    child: const Text('Setup Notification Schedule'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Connection Settings Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.settings_ethernet, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Connection',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isConnectionSettingsExpanded = !_isConnectionSettingsExpanded;
                      });
                    },
                    child: const Text('Manage Connection'),
                  ),
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

          // Localization Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.language, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Localization',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                    ),
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
                        child: Text(value == 'de_DE' ? 'German' : 'English'),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // User Profile Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/icon_topic_profile.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'User profile',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _authService.logout(() {});
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
