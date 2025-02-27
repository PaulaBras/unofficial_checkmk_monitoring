import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'colors.dart';
import 'screens/help/help.dart';
import 'screens/myHomePage.dart';
import 'screens/user/loginScreen.dart';
import 'screens/user/user.dart';
import 'screens/user/welcomeScreen.dart';
import 'services/notificationHandler.dart';
import 'services/secureStorage.dart';
import 'services/themeNotifier.dart';
import 'services/authService.dart';
import 'services/apiRequest.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String welcomeScreenId = 'welcome_screen';
const String loginScreenId = 'login_screen';
const String registrationScreenId = 'registration_screen';
const String homeScreenId = 'home_screen';
const String helpScreenId = 'help_screen';
const String userScreenId = 'user_screen';

String? selectedNotificationPayload;

CheckmkNotificationService? notificationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<void> configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  await configureLocalTimeZone();

  final SecureStorage storage = SecureStorage();
  final AuthenticationService authService = AuthenticationService(storage, ApiRequest());

  // Check if credentials are already saved
  final savedCredentials = await authService.loadCredentials();
  final initialRoute = savedCredentials != null ? homeScreenId : welcomeScreenId;

  // Initialize the FlutterBackground plugin with minimal notification
  // We'll use our own persistent notification instead
  final success = await FlutterBackground.initialize(
      androidConfig: FlutterBackgroundAndroidConfig(
    notificationTitle: "CheckMK Monitoring",
    notificationText: "Background service running",
    notificationIcon:
        AndroidResource(name: 'launcher_icon', defType: 'drawable'),
    // We'll use our own notification, so we don't need to set importance here
  ));

  if (success) {
    // Initialize the global notificationService variable
    notificationService = CheckmkNotificationService();

    // Request notification permissions
    await notificationService!.requestNotificationsPermission();
    
    // Set initial background state (app starts in foreground)
    notificationService!.setAppInBackground(false);
    
    // Start the notification service (now async)
    await notificationService!.start();

    // handle notification selection
    selectNotificationStream.stream.listen((payload) async {
      // Handle the user's response to the notification here
      // ignore: avoid_print
      print('Notification selected with payload: $payload');
    });

    // Enable the background execution
    await FlutterBackground.enableBackgroundExecution();
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('firstRun') ?? true) {
    await storage.init();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('dateFormat', 'dd.MM.yyyy, HH:mm');
    prefs.setString('locale', 'de_DE');
    prefs.setBool('firstRun', false);
  }

  initializeDateFormatting().then((_) {
    Intl.defaultLocale = 'de_DE';
    runApp(
      ChangeNotifierProvider<ThemeNotifier>(
        create: (_) => ThemeNotifier(),
        child: MyApp(initialRoute: initialRoute),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update the notification service with the app's background state
    if (notificationService != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          // App is in the foreground
          notificationService!.setAppInBackground(false);
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
          // App is in the background or closed
          notificationService!.setAppInBackground(true);
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: "CheckMK Monitoring",
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      themeMode: themeNotifier.darkTheme ? ThemeMode.dark : ThemeMode.light,
      initialRoute: widget.initialRoute,
      onGenerateRoute: getRoute,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
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
