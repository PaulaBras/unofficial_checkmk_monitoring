import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/screens/main/my_home_page.dart';
import 'package:ptp_4_monitoring_app/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  void _login() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Überprüfe die Zugangsdaten
      if (_username == 'test' && _password == 'test') {
        // Weiterleitung zur nächsten Route
        Navigator.pushNamed(context, MyHomePage.id);
      } else {
        // Fehlermeldung anzeigen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ungültige Zugangsdaten'),
          ),
        );
      }
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
                labelText: 'Benutzername',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Bitte geben Sie einen Benutzernamen ein';
                  }
                  return null;
                },
                onSaved: (value) => _username = value!,
              ),
              const SizedBox(height: 16.0),
              CustomTextField(
                labelText: 'Passwort',
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Bitte geben Sie ein Passwort ein';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Anmelden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}