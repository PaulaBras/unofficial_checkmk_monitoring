import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

import '../../services/secureStorage.dart';

class UserConfig extends StatefulWidget {
  @override
  _UserConfigState createState() => _UserConfigState();
}

class _UserConfigState extends State<UserConfig> {
  Map<String, dynamic>? userConfig;

  @override
  void initState() {
    super.initState();
    _getUserConfig();
  }

  Future<void> _getUserConfig() async {
    var secureStorage = SecureStorage();
    var api = ApiRequest();
    var username = await secureStorage.readSecureData('username');
    var data = await api.Request('objects/user_config/$username');
    setState(() {
      userConfig = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Config'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: userConfig == null
            ? CircularProgressIndicator()
            : UserConfigWidget(userConfig: userConfig!),
      ),
    );
  }
}

class UserConfigWidget extends StatelessWidget {
  final Map<String, dynamic> userConfig;

  UserConfigWidget({required this.userConfig});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ID: ${userConfig['id']}'),
        Text('Title: ${userConfig['title']}'),
        Text('Full Name: ${userConfig['extensions']['fullname']}'),
        Text('Email: ${userConfig['extensions']['contact_options']['email']}'),
        Text(
            'Fallback Contact: ${userConfig['extensions']['contact_options']['fallback_contact']}'),
        Text(
            'Idle Timeout: ${userConfig['extensions']['idle_timeout']['option']}'),
        Text('Roles: ${userConfig['extensions']['roles'].join(', ')}'),
        Text(
            'Contact Groups: ${userConfig['extensions']['contactgroups'].join(', ')}'),
        Text(
            'Auth Option: ${userConfig['extensions']['auth_option']['auth_type']}'),
        // Add more fields as needed
      ],
    );
  }
}
