import 'package:flutter/material.dart';

import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';
import '/widgets/customTextField.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest();
  late AuthenticationService authService;

  // Define the instance variables
  String _server = '';
  String _username = '';
  String _password = '';
  String _site = '';
  bool _ignoreCertificate = false;
  final _formKey = GlobalKey<FormState>();
  bool _showLoginForm = false;

  @override
  void initState() {
    super.initState();
    authService = AuthenticationService(secureStorage, apiRequest);
    _loadCredentials();
  }

  void _loadCredentials() {
    authService.loadCredentials().then((credentials) {
      if (credentials != null) {
        setState(() {
          _server = credentials.server;
          _username = credentials.username;
          _password = credentials.password;
          _site = credentials.site;
          _ignoreCertificate = credentials.ignoreCertificate;
          _showLoginForm = false;
        });
        _login();
      } else {
        setState(() {
          _showLoginForm = true; // Add this line
        });
      }
    });
  }

  void _login() async {
    bool loginSuccessful = await authService.login(
        _server, _username, _password, _site, _ignoreCertificate);
    if (loginSuccessful) {
      Navigator.pushNamed(context, 'home_screen');
    } else {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
      Navigator.pushNamed(context, 'login_screen');
    }
  }

  void _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await authService.saveCredentials(
          _server, _username, _password, _site, _ignoreCertificate);
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: _showLoginForm // Use the _showLoginForm variable here
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                      ),
                      const SizedBox(height: 16.0),
                      SwitchListTile(
                        title: const Text('Ignore Certificate Warnings'),
                        value: _ignoreCertificate,
                        onChanged: (bool value) {
                          setState(() {
                            _ignoreCertificate = value;
                          });
                        },
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
