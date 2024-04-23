import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/screens/login_screen.dart';
import 'package:ptp_4_monitoring_app/screens/registration_screen.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Hero(
                  tag: 'logo',
                  child: Container(
                    child: Image.asset('images/checkmk-logo-white.png'),
                    height: 60.0,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 48.0,
            ),
            ElevatedButton(
              child: Text('Log In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushNamed(context, LoginScreen.id);
              },
            ),
            ElevatedButton(
              child: Text('Register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushNamed(context, RegistrationScreen.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
