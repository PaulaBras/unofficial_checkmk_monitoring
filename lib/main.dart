import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:ptp_4_monitoring_app/colors.dart';
import 'package:ptp_4_monitoring_app/screens/help/help.dart';
import 'package:ptp_4_monitoring_app/screens/my_home_page.dart';
import 'package:ptp_4_monitoring_app/screens/notify/notify.dart';
import 'package:ptp_4_monitoring_app/screens/user/login_screen.dart';
import 'package:ptp_4_monitoring_app/screens/user/user.dart';
import 'package:ptp_4_monitoring_app/screens/user/welcome_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const String welcomeScreenId = 'welcome_screen';
const String loginScreenId = 'login_screen';
const String registrationScreenId = 'registration_screen';
const String homeScreenId = 'home_screen';
const String helpScreenId = 'help_screen';
const String userScreenId = 'user_screen';

NotificationService? notificationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize the global notificationService variable
  notificationService = NotificationService(flutterLocalNotificationsPlugin);

  notificationService!.test();
  notificationService!.start();

  initializeDateFormatting().then((_) {
    Intl.defaultLocale = 'de_DE';
    runApp(const MyApp());
  });
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
      case homeScreenId:
        return MaterialPageRoute(builder: (_) => MyHomePage());
      case helpScreenId:
        return MaterialPageRoute(builder: (_) => HelpScreen());
      case userScreenId:
        return MaterialPageRoute(builder: (_) => UserScreen());
      default:
        return null;
    }
  }
}
