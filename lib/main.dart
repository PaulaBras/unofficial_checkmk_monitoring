import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/colors.dart';
import 'package:ptp_4_monitoring_app/screens/login_screen.dart';
import 'package:ptp_4_monitoring_app/screens/my_home_page.dart';
import 'package:ptp_4_monitoring_app/screens/registration_screen.dart';
import 'package:ptp_4_monitoring_app/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CheckMK Monitoring",
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      themeMode: ThemeMode.dark,
      initialRoute: MyHomePage.id,
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        MyHomePage.id: (context) => MyHomePage(),
      },
    );
  }
}
