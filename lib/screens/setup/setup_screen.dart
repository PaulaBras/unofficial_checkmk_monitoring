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
    setState(() {});
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
          child: Text('Setup Screen'),
        ),
      ),
    );
  }
}
