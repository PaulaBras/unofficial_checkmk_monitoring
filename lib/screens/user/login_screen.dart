import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/widgets/custom_text_field.dart';

import '../../models/credentials.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var secureStorage = SecureStorage();
  String _server = '';
  String _username = '';
  String _password = '';
  String _site = '';
  bool _ignoreCertificate = false;
  final _formKey = GlobalKey<FormState>();

  void _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Save the credentials to secure storage
      // await secureStorage.writeSecureData('server', _server);
      // await secureStorage.writeSecureData('username', _username);
      // await secureStorage.writeSecureData('password', _password);
      // await secureStorage.writeSecureData('site', _site);
      // await secureStorage.writeSecureData('ignoreCertificate', _ignoreCertificate.toString());
      // Navigate to the welcome screen
      Navigator.pushNamed(context, 'home_screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
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
    );
  }
}