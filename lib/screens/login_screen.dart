import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _server;
  String? _username;
  String? _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Server (domain or IP)'),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter the server';
                }
                return null;
              },
              onSaved: (value) => _server = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your username';
                }
                return null;
              },
              onSaved: (value) => _username = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your password';
                }
                return null;
              },
              onSaved: (value) => _password = value,
            ),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  // TODO: Perform login with _server, _username, and _password
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}