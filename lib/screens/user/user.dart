import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';
import '../../services/notificationHandler.dart';
import '/screens/myHomePage.dart';
import '/screens/user/loginScreen.dart';
import '/services/themeNotifier.dart';
import '/widgets/appBarWidget.dart';
import '../setup/ConnectionSettingsWidget.dart';
import '../notify/notify.dart';
import '../setup/AreNotificationsActive.dart';
import '../setup/SetupNotificationSchedule.dart';
import '../../colors.dart';

class UserScreen extends StatefulWidget {
  final bool fromDrawer;

  const UserScreen({super.key, this.fromDrawer = false});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest();
  late AuthenticationService authService;
  final CheckmkNotificationService _notificationService = CheckmkNotificationService();
  
  String _startPage = 'Dashboard';
  bool _notification = true;
  bool _notificationSchedule = false;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  bool _isConnectionSettingsExpanded = false;

  // Service state notification settings
  Map<String, bool> _serviceStateNotifications = {
    'green': true,
    'warning': true,
    'critical': true,
    'unknown': true,
  };

  Map<String, int> pageNameToIndex = {
    'Dashboard': 0,
    'Service': 1,
    'Host': 2,
  };

  @override
  void initState() {
    super.initState();
    authService = AuthenticationService(secureStorage, apiRequest);
    final myHomePageLogic = MyHomePageLogic();
    myHomePageLogic.loadStartIndex().then((value) {
      setState(() {
        _startPage = pageNameToIndex.keys.elementAt(value);
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
      String? savedSetting = await secureStorage.readSecureData('notify_$state');
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
      await secureStorage.writeSecureData('notify_${entry.key}', entry.value.toString());
    }
  }

  void _toggleServiceNotification(String state, bool value) async {
    await secureStorage.writeSecureData('notify_$state', value.toString());
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
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
            margin: EdgeInsets.all(8),
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
                      SizedBox(width: 10),
                      Text(
                        'User interface',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: Text('Dark Theme'),
                  value: themeNotifier.darkTheme,
                  onChanged: (value) {
                    setState(() {
                      themeNotifier.toggleTheme();
                    });
                  },
                ),
                ListTile(
                  title: Text('Set Start Page'),
                  trailing: DropdownButton<String>(
                    value: _startPage,
                    items: pageNameToIndex.keys.map((pageName) {
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
                        myHomePageLogic.updateStartIndex(pageNameToIndex[newValue]!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Notifications Section
          Card(
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: colorScheme.primary),
                      SizedBox(width: 10),
                      Text(
                        'Notifications',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
                
                // Service State Notification Settings
                ExpansionTile(
                  title: Text('Service State Notifications'),
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
                        SnackBar(content: Text('Test notification sent'), duration: Duration(seconds: 1)),
                      );
                    } : null,
                    child: Text('Send Test Notification'),
                  ),
                ),
                SizedBox(height: 8),
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
                    child: Text('Setup Notification Schedule'),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),

          // Connection Settings Section
          Card(
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.settings_ethernet, color: colorScheme.primary),
                      SizedBox(width: 10),
                      Text(
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
                    child: Text('Manage Connection'),
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
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.language, color: colorScheme.primary),
                      SizedBox(width: 10),
                      Text(
                        'Localization',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
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
                SizedBox(height: 8),
              ],
            ),
          ),

          // User Profile Section
          Card(
            margin: EdgeInsets.all(8),
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
                      SizedBox(width: 10),
                      Text(
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
                      await authService.logout(() {});
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text('Logout'),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
