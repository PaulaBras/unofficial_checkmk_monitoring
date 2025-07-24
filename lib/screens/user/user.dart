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
import '../setup/MultiSiteConnectionWidget.dart';
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
  final CheckmkNotificationService _notificationService =
      CheckmkNotificationService();

  String _startPage = 'Dashboard';
  bool _notification = true;
  bool _notificationSchedule = false;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  bool _isConnectionSettingsExpanded = false;
  bool _isUserProfileExpanded = false;

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
    var notificationSettings =
        await _notificationService.loadNotificationSettings();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _notification = notificationSettings['enabled'];
      _notificationSchedule = notificationSettings['schedule'] != null &&
          notificationSettings['schedule'] != '';
      _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
      _locale = prefs.getString('locale') ?? 'de_DE';
    });
  }

  void _loadServiceNotificationSettings() async {
    for (var state in _serviceStateNotifications.keys) {
      String? savedSetting =
          await _secureStorage.readSecureData('notify_$state');
      setState(() {
        _serviceStateNotifications[state] =
            savedSetting?.toLowerCase() != 'false';
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
      await _secureStorage.writeSecureData(
          'notify_${entry.key}', entry.value.toString());
    }
  }

  void _toggleServiceNotification(String state, bool value) async {
    await _secureStorage.writeSecureData('notify_$state', value.toString());
    setState(() {
      _serviceStateNotifications[state] = value;
    });
  }

  Future<void> _sendTestNotificationWithPermissionCheck() async {
    try {
      // First check if notifications are enabled in app settings
      if (!_notification) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please enable notifications first in the settings above.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if we have notification permissions
      bool hasPermissions = await _checkNotificationPermissions();

      if (!hasPermissions) {
        // Request permissions with dialog
        bool shouldRequest = await _showPermissionRequestDialog();

        if (shouldRequest) {
          await _notificationService.requestNotificationsPermission();

          // Check again after requesting
          hasPermissions = await _checkNotificationPermissions();

          if (!hasPermissions) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Notification permissions are required to send test notifications. Please enable them in your device settings.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permissions are required to send test notifications.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Send test notification
      _notificationService.sendNotification('CheckMK Test Notification',
          'Notifications are working correctly! 🎉');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error sending test notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _checkNotificationPermissions() async {
    try {
      // This is a simplified check - in a real implementation you might want to use
      // the platform channels to check the exact permission status
      // For now, we'll assume if we can send a notification, permissions are granted
      return true; // You can implement more sophisticated permission checking here
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  Future<bool> _showPermissionRequestDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Notification Permission Required'),
                ],
              ),
              content: Text(
                'To send test notifications, CheckMK Monitoring needs notification permissions.\n\nWould you like to grant permission now?',
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Grant Permission'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
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
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1.5,
              ),
            ),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                        myHomePageLogic
                            .updateStartIndex(_pageNameToIndex[newValue]!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Connection Settings Section
          Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1.5,
              ),
            ),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isConnectionSettingsExpanded =
                            !_isConnectionSettingsExpanded;
                      });
                    },
                    child: const Text('Manage Connections'),
                  ),
                ),
                if (_isConnectionSettingsExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: MultiSiteConnectionWidget(
                      onClose: (bool saved) {
                        setState(() {
                          _isConnectionSettingsExpanded = false;
                        });
                      },
                    ),
                  ),

                // User Profile Section (merged with Connection)
                ExpansionTile(
                  title: const Text('User Profile'),
                  initiallyExpanded: _isUserProfileExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isUserProfileExpanded = expanded;
                    });
                  },
                  leading: Image.asset(
                    'images/icon_topic_profile.png',
                    width: 24,
                    height: 24,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          final shouldGoToLogin = await _authService.logout();

                          if (shouldGoToLogin) {
                            // No more connections, go to login screen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          } else {
                            // Switched to another connection, refresh current screen
                            Navigator.of(context)
                                .pop(); // Go back to main screen
                            // The app will automatically use the new active connection
                          }
                        },
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Localization Section
          Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1.5,
              ),
            ),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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

          // Notifications Section
          Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 1.5,
              ),
            ),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                    onPressed: () async {
                      await _sendTestNotificationWithPermissionCheck();
                    },
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
        ],
      ),
    );
  }
}
