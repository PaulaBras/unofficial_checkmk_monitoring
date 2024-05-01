import 'package:flutter/material.dart';
import '../../models/credentials.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
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
    _ignoreCertificate = (await secureStorage.readSecureData('ignoreCertificate'))?.toLowerCase() == 'true' ?? false;
    setState(() {});
  }

  void _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await secureStorage.writeSecureData('server', _server);
      await secureStorage.writeSecureData('username', _username);
      await secureStorage.writeSecureData('password', _password);
      await secureStorage.writeSecureData('site', _site);
      await secureStorage.writeSecureData('ignoreCertificate', _ignoreCertificate.toString());
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
                initialValue: _server,
                decoration: InputDecoration(
                  labelText: 'Server',
                ),
                onSaved: (value) => _server = value!,
              ),
              TextFormField(
                initialValue: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                ),
                onSaved: (value) => _username = value!,
              ),
              TextFormField(
                initialValue: _password,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                onSaved: (value) => _password = value!,
              ),
              TextFormField(
                initialValue: _site,
                decoration: InputDecoration(
                  labelText: 'Site',
                ),
                onSaved: (value) => _site = value!,
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