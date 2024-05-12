import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/models/credentials.dart';
import 'package:ptp_4_monitoring_app/widgets/custom_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    _server = await secureStorage.readSecureData('server') ?? '';
    _username = await secureStorage.readSecureData('username') ?? '';
    _password = await secureStorage.readSecureData('password') ?? '';
    _site = await secureStorage.readSecureData('site') ?? '';
    _ignoreCertificate =
        (await secureStorage.readSecureData('ignoreCertificate'))
                ?.toLowerCase() ==
            'true';
    if (_server.isNotEmpty &&
        _username.isNotEmpty &&
        _password.isNotEmpty &&
        _site.isNotEmpty) {
      _login();
    } else {
      setState(() {});
    }
  }

  void _login() async {
    // Implement your login logic here
    Navigator.pushNamed(context, 'home_screen');
  }

  void _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await secureStorage.writeSecureData('server', _server);
      await secureStorage.writeSecureData('username', _username);
      await secureStorage.writeSecureData('password', _password);
      await secureStorage.writeSecureData('site', _site);
      await secureStorage.writeSecureData(
          'ignoreCertificate', _ignoreCertificate.toString());
      _login();
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
      ),
    );
  }
}
