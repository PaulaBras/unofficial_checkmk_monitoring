import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '/widgets/customTextField.dart';
import '../../models/site_connection.dart';
import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';
import '../../services/site_connection_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest();
  late AuthenticationService authService;
  late SiteConnectionService connectionService;
  WebViewController? _webViewController;

  // Define the instance variables
  String _connectionName = 'Default Connection';
  String _server = '';
  String _username = '';
  String _password = '';
  String _site = '';
  String _protocol = 'https';
  String _authType = 'basic';
  bool _ignoreCertificate = false;
  final _formKey = GlobalKey<FormState>();
  bool _showLoginForm = false;
  bool _isLoading = true;
  bool _showWebView = false;

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
    if (mounted) {
      setState(() {
        _showLoginForm = true;
        _isLoading = false;
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
        authType: _authType,
      );

      // Add the connection
      final newConnection = await connectionService.addConnection(connection);

      // Set it as active
      await connectionService.setActiveConnection(newConnection.id);

      if (_authType == 'saml') {
        // For SAML, show WebView with the SAML login page
        setState(() {
          _showWebView = true;
          _isLoading = false;
        });
        return;
      }

      // For basic auth, use RequestWithCredentials
      final response = await apiRequest.RequestWithCredentials(
        _protocol,
        _server,
        _username,
        _password,
        _site,
        _ignoreCertificate,
        '/objects/site_connection/${_site}/actions/login/invoke',
        method: 'POST',
        body: {
          'username': _username,
          'password': _password,
        },
        timeoutSeconds: 15,
      );

      if (!mounted) return;

      if (response != null) {
        Navigator.pushReplacementNamed(context, 'home_screen');
      } else {
        setState(() {
          _isLoading = false;
        });
        // Show an error message with the actual error from the API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(apiRequest.getErrorMessage() ?? 'Login failed. Please check your credentials.')),
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
    if (_showWebView) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SAML Login'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showWebView = false;
              });
            },
          ),
        ),
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse('$_protocol://$_server${_site.isNotEmpty ? '/$_site' : ''}/check_mk/saml.py'))
            ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (NavigationRequest request) {
                  // Check if the URL indicates successful SAML login
                  if (request.url.contains('check_mk/dashboard.py')) {
                    Navigator.pushReplacementNamed(context, 'home_screen');
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            ),
        ),
      );
    }

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
                                _connectionName = value.isNotEmpty ? value : 'Default Connection';
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
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
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _authType,
                                  decoration: InputDecoration(
                                    labelText: 'Authentication',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: <String>['basic', 'saml']
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value.toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _authType = newValue!;
                                      // Clear username/password when switching to SAML
                                      if (newValue == 'saml') {
                                        _username = '';
                                        _password = '';
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
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
                            },
                          ),
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
                          if (_authType == 'basic') ...[
                            const SizedBox(height: 16.0),
                            CustomTextField(
                              initialValue: _username,
                              labelText: 'Username',
                              validator: (value) {
                                if (_authType == 'basic' && value!.isEmpty) {
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
                                if (_authType == 'basic' && value!.isEmpty) {
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
                          ],
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
                            child: Text(_authType == 'saml' ? 'Continue to SAML Login' : 'Login'),
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
