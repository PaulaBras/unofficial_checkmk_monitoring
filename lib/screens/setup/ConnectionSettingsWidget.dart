import 'package:flutter/material.dart';
import '../../services/secureStorage.dart';
import '../../services/apiRequest.dart';
import '../../services/authService.dart';

class ConnectionSettingsWidget extends StatefulWidget {
  final Function(bool) onClose;

  const ConnectionSettingsWidget({Key? key, required this.onClose}) : super(key: key);

  @override
  _ConnectionSettingsWidgetState createState() => _ConnectionSettingsWidgetState();
}

class _ConnectionSettingsWidgetState extends State<ConnectionSettingsWidget> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest();
  late AuthenticationService authService;

  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _siteController = TextEditingController();
  
  bool _ignoreCertificate = false;
  String _protocol = 'https';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    authService = AuthenticationService(secureStorage, apiRequest);
    _loadConnectionSettings();
  }

  void _loadConnectionSettings() async {
    _protocol = await secureStorage.readSecureData('protocol') ?? 'https';
    _serverController.text = await secureStorage.readSecureData('server') ?? '';
    _usernameController.text = await secureStorage.readSecureData('username') ?? '';
    _passwordController.text = await secureStorage.readSecureData('password') ?? '';
    _siteController.text = await secureStorage.readSecureData('site') ?? '';
    _ignoreCertificate = (await secureStorage.readSecureData('ignoreCertificate'))?.toLowerCase() == 'true';
    
    setState(() {});
  }

  Future<bool> _saveConnectionSettings() async {
    if (_formKey.currentState!.validate()) {
      await secureStorage.writeSecureData('protocol', _protocol);
      await secureStorage.writeSecureData('server', _serverController.text);
      await secureStorage.writeSecureData('username', _usernameController.text);
      await secureStorage.writeSecureData('password', _passwordController.text);
      await secureStorage.writeSecureData('site', _siteController.text);
      await secureStorage.writeSecureData('ignoreCertificate', _ignoreCertificate.toString());

      bool loginSuccessful = await authService.login(
        _usernameController.text, 
        _passwordController.text
      );

      return loginSuccessful;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          SizedBox(height: 10),
          TextFormField(
            controller: _serverController,
            decoration: InputDecoration(
              labelText: 'Server',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a server address';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _siteController,
            decoration: InputDecoration(
              labelText: 'Site',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => widget.onClose(false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool saveSuccessful = await _saveConnectionSettings();
                  if (saveSuccessful) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connection settings saved successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    widget.onClose(true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save connection settings'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _siteController.dispose();
    super.dispose();
  }
}
