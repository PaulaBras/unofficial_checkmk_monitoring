import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ptp_4_monitoring_app/colors.dart';
import 'package:ptp_4_monitoring_app/screens/help/help.dart';
import 'package:ptp_4_monitoring_app/screens/myHomePage.dart';
import 'package:ptp_4_monitoring_app/screens/notify/notify.dart';
import 'package:ptp_4_monitoring_app/screens/user/loginScreen.dart';
import 'package:ptp_4_monitoring_app/screens/user/user.dart';
import 'package:ptp_4_monitoring_app/screens/user/welcomeScreen.dart';
import 'package:ptp_4_monitoring_app/services/notificationHandler.dart';
import 'package:ptp_4_monitoring_app/services/secureStorage.dart';
import 'package:ptp_4_monitoring_app/services/themeNotifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String welcomeScreenId = 'welcome_screen';
const String loginScreenId = 'login_screen';
const String registrationScreenId = 'registration_screen';
const String homeScreenId = 'home_screen';
const String helpScreenId = 'help_screen';
const String userScreenId = 'user_screen';

String? selectedNotificationPayload;

NotificationService? notificationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  await _configureLocalTimeZone();

  // Initialize the global notificationService variable
  notificationService = NotificationService();

  // Request notification permissions
  await notificationService!.requestNotificationsPermission();

  // Start the notification service
  notificationService!.start();

  // handle notification selection
  selectNotificationStream.stream.listen((String? payload) async {
    // Handle the user's response to the notification here
    print('Notification selected with payload: $payload');
  });

  SecureStorage storage = SecureStorage();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('firstRun') ?? true) {
    await storage.init();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('dateFormat', 'dd.MM.yyyy, HH:mm');
    prefs.setString('locale', 'de_DE');
    prefs.setBool('firstRun', false);
  }

  initializeDateFormatting().then((_) {
    Intl.defaultLocale = 'de_DE';
    runApp(
      ChangeNotifierProvider<ThemeNotifier>(
        create: (_) => new ThemeNotifier(),
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: "CheckMK Monitoring",
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      themeMode: themeNotifier.darkTheme ? ThemeMode.dark : ThemeMode.light,
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
