import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/widgets/custom_text_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';

  void _register() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Implementiere hier die Registrierungslogik
      // Bei erfolgreicher Registrierung, navigiere zur nächsten Route
      // Navigator.pushNamed(context, MyHomePage.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrierung'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextField(
                initialValue: _username,
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
                initialValue: _email,
                labelText: 'E-Mail',
                validator: (value) {
                  if (value!.isEmpty || !value.contains('@')) {
                    return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 16.0),
              CustomTextField(
                initialValue: _password,
                labelText: 'Passwort',
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty || value.length < 6) {
                    return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Registrieren'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}