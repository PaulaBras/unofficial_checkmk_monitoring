import 'package:flutter/material.dart';

import '../../models/credentials.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  var secureStorage = SecureStorage();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _siteController = TextEditingController();
  bool _ignoreCertificate = false;
  bool _notification = false;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    _serverController.text = await secureStorage.readSecureData('server') ?? '';
    _usernameController.text =
        await secureStorage.readSecureData('username') ?? '';
    _passwordController.text =
        await secureStorage.readSecureData('password') ?? '';
    _siteController.text = await secureStorage.readSecureData('site') ?? '';
    _ignoreCertificate = (await secureStorage.readSecureData('ignoreCertificate'))?.toLowerCase() == 'true' ?? false;
    _notification = (await secureStorage.readSecureData('notification'))?.toLowerCase() == 'true' ?? false;
    _dateFormat = await secureStorage.readSecureData('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = await secureStorage.readSecureData('locale') ?? 'de_DE';
    setState(() {});
  }

  void _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await secureStorage.writeSecureData('server', _serverController.text);
      await secureStorage.writeSecureData('username', _usernameController.text);
      await secureStorage.writeSecureData('password', _passwordController.text);
      await secureStorage.writeSecureData('site', _siteController.text);
      await secureStorage.writeSecureData('ignoreCertificate', _ignoreCertificate.toString());
      await secureStorage.writeSecureData('notification', _notification.toString());
      await secureStorage.writeSecureData('dateFormat', _dateFormat);
      await secureStorage.writeSecureData('locale', _locale);
      Navigator.pop(context);
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
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
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
                onChanged: (bool value) {
                  setState(() {
                    _ignoreCertificate = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Enable Notification'),
                value: _notification,
                onChanged: (bool value) {
                  setState(() {
                    _notification = value;
                  });
                },
              ),
              DropdownButton<String>(
                value: _locale,
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      _dateFormat = newValue == 'de_DE' ? 'dd.MM.yyyy, HH:mm' : 'MM/dd/yyyy, hh:mm a';
                      _locale = newValue;
                    }
                  });
                },
                items: <String>['de_DE', 'en_US'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: _saveCredentials,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
