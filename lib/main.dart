import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/colors.dart';
import 'package:ptp_4_monitoring_app/screens/user/login_screen.dart';
import 'package:ptp_4_monitoring_app/screens/main/my_home_page.dart';
import 'package:ptp_4_monitoring_app/screens/user/registration_screen.dart';
import 'package:ptp_4_monitoring_app/screens/user/welcome_screen.dart';

const String welcomeScreenId = 'welcome_screen';
const String loginScreenId = 'login_screen';
const String registrationScreenId = 'registration_screen';
const String homeScreenId = 'home_screen';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CheckMK Monitoring",
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      themeMode: ThemeMode.dark,
      initialRoute: welcomeScreenId,
      onGenerateRoute: getRoute,
    );
  }

  Route<dynamic>? getRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcomeScreenId:
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
      case loginScreenId:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case registrationScreenId:
        return MaterialPageRoute(builder: (_) => RegistrationScreen());
      case homeScreenId:
        return MaterialPageRoute(builder: (_) => MyHomePage());
      default:
        return null;
    }
  }
}