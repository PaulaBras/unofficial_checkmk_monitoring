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
import 'screens/setup/BatteryOptimizationScreen.dart';
import 'screens/user/loginScreen.dart';
import 'screens/user/user.dart';
import 'screens/user/welcomeScreen.dart';
import 'services/battery_optimization_service.dart';
import 'services/notificationHandler.dart';
import 'services/secureStorage.dart';
import 'services/themeNotifier.dart';
import 'services/authService.dart';
import 'services/apiRequest.dart';
import 'services/widget/dashboard_widget_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String welcomeScreenId = 'welcome_screen';
const String loginScreenId = 'login_screen';
const String registrationScreenId = 'registration_screen';
const String homeScreenId = 'home_screen';
const String helpScreenId = 'help_screen';
const String userScreenId = 'user_screen';
const String batteryOptimizationScreenId = 'battery_optimization_screen';

String? selectedNotificationPayload;

CheckmkNotificationService? notificationService;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Default to login screen in case of any initialization errors
  String initialRoute = loginScreenId;

  try {
    await _configureLocalTimeZone();

    final SecureStorage storage = SecureStorage();
    final AuthenticationService authService =
        AuthenticationService(storage, ApiRequest());

    // Initialize the dashboard widget service
    DashboardWidgetService();

    try {
      // Check if credentials are already saved
      final savedCredentials = await authService.loadCredentials();
      if (savedCredentials != null) {
        initialRoute = homeScreenId;
      } else {
        // No saved credentials, go directly to login screen
        initialRoute = loginScreenId;
      }
    } catch (e) {
      // If loading credentials fails, default to login screen
      print('Error loading credentials: $e');
      initialRoute = loginScreenId;
    }

    // Initialize background services - now we wait for it to complete
    await _initializeBackgroundServices();

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('firstRun') ?? true) {
      try {
        await storage.init();
        prefs.setString('dateFormat', 'dd.MM.yyyy, HH:mm');
        prefs.setString('locale', 'de_DE');
        prefs.setBool('firstRun', false);
      } catch (e) {
        print('Error during first run setup: $e');
      }
    }
  } catch (e) {
    print('Error during app initialization: $e');
    // Continue with login screen if there's any error
  }

  // Start the app regardless of initialization errors
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

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  try {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    print('Error configuring timezone: $e');
  }
}

// Initialize background services - now returns a Future that can be awaited
Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize the FlutterBackground plugin with minimal notification
    final success = await FlutterBackground.initialize(
        androidConfig: FlutterBackgroundAndroidConfig(
      notificationTitle: "CheckMK Monitoring",
      notificationText: "Background service running",
      notificationIcon: AndroidResource(name: 'app_icon', defType: 'drawable'),
    ));

    if (success) {
      try {
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
        });

        // Enable the background execution
        await FlutterBackground.enableBackgroundExecution();

        print('Background services initialized successfully');
      } catch (e) {
        print('Error initializing notification service: $e');
      }
    } else {
      print('Failed to initialize FlutterBackground plugin');
    }
  } catch (e) {
    print('Error initializing background services: $e');
  }
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
      case batteryOptimizationScreenId:
        return MaterialPageRoute(
            builder: (_) => const BatteryOptimizationScreen());
      default:
        return null;
    }
  }
}
