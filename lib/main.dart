import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/screens/my_home_page.dart';
import 'package:ptp_4_monitoring_app/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckMK Monitoring',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'CheckMK Monitoring'),
    );
  }
}
