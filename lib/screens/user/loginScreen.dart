import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';

import '/widgets/customTextField.dart';
import '../../models/site_connection.dart';
import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';
import '../../services/site_connection_service.dart';
import '../../services/notificationHandler.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest();
  late AuthenticationService authService;
  late SiteConnectionService connectionService;

  // Define the instance variables
  String _connectionName = 'Default Connection';
  String _server = '';
  String _username = '';
  String _password = '';
  String _site = '';
  String _protocol = 'https';
  bool _ignoreCertificate = false;
  final _formKey = GlobalKey<FormState>();
  bool _showLoginForm = false;
  bool _isLoading = true;

  // DNS resolution state
  String? _resolvedIP;
  String? _dnsError;
  bool _isDnsResolving = false;

  @override
  void initState() {
    super.initState();
    authService = AuthenticationService(secureStorage, apiRequest);
    connectionService = SiteConnectionService(secureStorage);
    _checkExistingConnections();
  }

  void _checkExistingConnections() async {
    try {
      // First, migrate any legacy connection
      await connectionService.migrateLegacyConnection();

      // Check if we have any connections
      final connections = await connectionService.getAllConnections();
      final activeConnectionId =
          await connectionService.getActiveConnectionId();

      if (connections.isNotEmpty && activeConnectionId != null) {
        // We have connections and an active connection, try to login
        try {
          final loginSuccessful = await authService.loginWithActiveConnection();
          if (loginSuccessful) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, 'home_screen');
            }
            return;
          }
        } catch (e) {
          print('Error during automatic login: $e');
          // Continue to login form
        }
      }
    } catch (e) {
      print('Error checking existing connections: $e');
      // Continue to login form regardless of error
    }

    // If we get here, either we have no connections, login failed, or there was an error
    // Check if this is first run and request permissions
    await _checkAndRequestPermissions();

    if (mounted) {
      setState(() {
        _showLoginForm = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isFirstRun = prefs.getBool('firstRun') ?? true;

      print('Checking permissions. First run: $isFirstRun');

      if (isFirstRun) {
        print('First run detected, requesting background permissions...');

        // Only request background execution permissions during initial setup
        await _requestBackgroundPermissionExplicitly();

        // NOTE: Don't set firstRun to false here - do it after login and notification permissions
        print('Initial background permissions requested');
      }
    } catch (e) {
      print('Error checking/requesting permissions: $e');
    }
  }

  Future<void> _requestNotificationPermissionExplicitly() async {
    // Show notification permission dialog first
    final bool? shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue),
              SizedBox(width: 8),
              Text('Enable Notifications'),
            ],
          ),
          content: Text(
            'CheckMK Monitoring needs notification permissions to alert you about system issues and monitoring events.\n\nPlease allow notifications in the next dialog.',
          ),
          actions: [
            TextButton(
              child: Text('Allow Notifications'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              child: Text('Skip'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      try {
        // Create notification service instance if global one is null
        CheckmkNotificationService localNotificationService;
        if (notificationService != null) {
          localNotificationService = notificationService!;
        } else {
          print('Global notification service is null, creating new instance');
          localNotificationService = CheckmkNotificationService();
        }

        await localNotificationService.requestNotificationsPermission();
      } catch (e) {
        print('Error requesting notification permissions: $e');
      }
    }
  }

  Future<void> _requestBackgroundPermissionExplicitly() async {
    if (Platform.isAndroid) {
      // Show background permission dialog
      final bool? shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.battery_full, color: Colors.green),
                SizedBox(width: 8),
                Text('Enable Background Operation'),
              ],
            ),
            content: Text(
              'CheckMK Monitoring needs to run in the background to continuously monitor your systems.\n\nPlease allow background operation in the next dialog.',
            ),
            actions: [
              TextButton(
                child: Text('Allow Background'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              TextButton(
                child: Text('Skip'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          );
        },
      );

      if (shouldRequest == true) {
        try {
          final hasPermission = await FlutterBackground.hasPermissions;
          if (!hasPermission) {
            await FlutterBackground.initialize(
                androidConfig: FlutterBackgroundAndroidConfig(
              notificationTitle: "CheckMK Monitoring",
              notificationText: "Background service running",
              notificationIcon:
                  AndroidResource(name: 'app_icon', defType: 'drawable'),
            ));
          }
        } catch (e) {
          print('Error requesting background permissions: $e');
        }
      }
    }
  }

  Future<void> _showPermissionSetupDialog() async {
    print('_showPermissionSetupDialog called');

    if (!mounted) {
      print('Widget not mounted, cannot show dialog');
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        print('Dialog builder called');
        return AlertDialog(
          title: Text('Setup Notifications'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Welcome to CheckMK Monitoring!'),
                SizedBox(height: 12),
                Text(
                    'To receive alerts about your system status, please enable notifications:'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notification Alerts',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                            Text(
                                'Get notified about critical system issues and monitoring events'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                    'You can change these settings later in the app settings.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Enable Notifications'),
              onPressed: () async {
                print('Enable Notifications button pressed');
                Navigator.of(context).pop();
                await _requestAllPermissions();
              },
            ),
            TextButton(
              child: Text('Skip for Now'),
              onPressed: () {
                print('Skip for Now button pressed');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestAllPermissions() async {
    try {
      // Request notification permissions
      print('Requesting notification permissions...');

      // Create notification service instance if global one is null
      CheckmkNotificationService localNotificationService;
      if (notificationService != null) {
        localNotificationService = notificationService!;
      } else {
        print('Global notification service is null, creating new instance');
        localNotificationService = CheckmkNotificationService();
      }

      await localNotificationService.requestNotificationsPermission();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification permissions setup completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Notification permissions could not be set up. You can enable them later in settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _resolveDNS(String hostname) async {
    if (hostname.isEmpty) {
      setState(() {
        _resolvedIP = null;
        _dnsError = null;
        _isDnsResolving = false;
      });
      return;
    }

    setState(() {
      _isDnsResolving = true;
      _resolvedIP = null;
      _dnsError = null;
    });

    try {
      // Check if it's already an IP address
      if (RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(hostname)) {
        setState(() {
          _resolvedIP = hostname;
          _dnsError = null;
          _isDnsResolving = false;
        });
        return;
      }

      // Resolve DNS
      final addresses = await InternetAddress.lookup(hostname);
      if (addresses.isNotEmpty) {
        setState(() {
          _resolvedIP = addresses.first.address;
          _dnsError = null;
          _isDnsResolving = false;
        });
      } else {
        setState(() {
          _resolvedIP = null;
          _dnsError = 'No IP addresses found for hostname';
          _isDnsResolving = false;
        });
      }
    } catch (e) {
      setState(() {
        _resolvedIP = null;
        _dnsError = 'DNS resolution failed: $e';
        _isDnsResolving = false;
      });
    }
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new connection
      final connection = SiteConnection(
        id: '',
        name: _connectionName,
        protocol: _protocol,
        server: _server,
        site: _site,
        username: _username,
        password: _password,
        ignoreCertificate: _ignoreCertificate,
      );

      // Add the connection
      final newConnection = await connectionService.addConnection(connection);

      // Set it as active
      await connectionService.setActiveConnection(newConnection.id);

      // Use RequestWithCredentials for initial login since connection isn't active yet in ApiRequest
      bool response = await authService.login(_username, _password);

      if (!mounted) return;

      if (response) {
        // Check for first run and show notification permission setup dialog
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final bool isFirstRun = prefs.getBool('firstRun') ?? true;

        print('Login successful. First run: $isFirstRun');

        if (isFirstRun) {
          print('Showing notification permission setup dialog...');
          // Show notification permission setup dialog for first-time users
          try {
            await _showPermissionSetupDialog();
            // Mark first run as complete
            await prefs.setBool('firstRun', false);
            print('First run marked as complete');
          } catch (e) {
            print('Error showing permission dialog: $e');
            // Still mark first run as complete to avoid getting stuck
            await prefs.setBool('firstRun', false);
          }
        }

        // Add a small delay before navigation to ensure dialog is properly closed
        await Future.delayed(Duration(milliseconds: 100));

        if (mounted) {
          Navigator.pushReplacementNamed(context, 'home_screen');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        // Show a user-friendly error message for authentication failures
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Incorrect username or password. Please try again.')),
        );
      }
    } catch (e) {
      print('Error during login: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show a more generic error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Login failed. Please check your connection details and try again.')),
      );
    }
  }

  void _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _showLoginForm
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: _connectionName,
                            decoration: const InputDecoration(
                              labelText: 'Connection Name (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                null, // Optional field, no validation needed
                            onSaved: (value) => _connectionName =
                                value?.isNotEmpty == true
                                    ? value!
                                    : 'Default Connection',
                            onChanged: (value) {
                              setState(() {
                                _connectionName = value.isNotEmpty
                                    ? value
                                    : 'Default Connection';
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<String>(
                            value: _protocol,
                            decoration: InputDecoration(
                              labelText: 'Protocol',
                              border: OutlineInputBorder(),
                            ),
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
                          const SizedBox(height: 16.0),
                          CustomTextField(
                            initialValue: _server,
                            labelText: 'Server (Domain or IP)',
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter a server';
                              }
                              return null;
                            },
                            onSaved: (value) => _server = value!,
                            onChanged: (value) {
                              setState(() {
                                _server = value;
                              });
                              // Trigger DNS resolution with a delay to avoid too many requests
                              if (value.isNotEmpty) {
                                Future.delayed(Duration(milliseconds: 500), () {
                                  if (_server == value) {
                                    _resolveDNS(value);
                                  }
                                });
                              } else {
                                _resolveDNS('');
                              }
                            },
                          ),
                          // DNS Resolution Result Widget
                          if (_server.isNotEmpty) ...[
                            const SizedBox(height: 8.0),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: _dnsError != null
                                    ? Colors.red.withOpacity(0.1)
                                    : _resolvedIP != null
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                border: Border.all(
                                  color: _dnsError != null
                                      ? Colors.red
                                      : _resolvedIP != null
                                          ? Colors.green
                                          : Colors.blue,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Row(
                                children: [
                                  if (_isDnsResolving)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    Icon(
                                      _dnsError != null
                                          ? Icons.error
                                          : _resolvedIP != null
                                              ? Icons.check_circle
                                              : Icons.info,
                                      color: _dnsError != null
                                          ? Colors.red
                                          : _resolvedIP != null
                                              ? Colors.green
                                              : Colors.blue,
                                      size: 16,
                                    ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isDnsResolving
                                          ? 'Resolving DNS...'
                                          : _dnsError != null
                                              ? _dnsError!
                                              : _resolvedIP != null
                                                  ? 'Resolved to: $_resolvedIP'
                                                  : 'Enter a server name to resolve DNS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _dnsError != null
                                            ? Colors.red.shade700
                                            : _resolvedIP != null
                                                ? Colors.green.shade700
                                                : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16.0),
                          CustomTextField(
                            initialValue: _site,
                            labelText: 'Site Name',
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter a site name';
                              }
                              return null;
                            },
                            onSaved: (value) => _site = value!,
                            onChanged: (value) {
                              setState(() {
                                _site = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          CustomTextField(
                            initialValue: _username,
                            labelText: 'Username',
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter a username';
                              }
                              return null;
                            },
                            onSaved: (value) => _username = value!,
                            onChanged: (value) {
                              setState(() {
                                _username = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          CustomTextField(
                            initialValue: _password,
                            labelText: 'Password',
                            obscureText: true,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter a password';
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value!,
                            onChanged: (value) {
                              setState(() {
                                _password = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          SwitchListTile(
                            title: Text('Ignore Certificate Warnings'),
                            value: _ignoreCertificate,
                            onChanged: _protocol == 'https'
                                ? (bool value) {
                                    setState(() {
                                      _ignoreCertificate = value;
                                    });
                                  }
                                : null,
                          ),
                          const SizedBox(height: 24.0),
                          ElevatedButton(
                            onPressed: _saveCredentials,
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Center(child: CircularProgressIndicator()),
    );
  }
}
