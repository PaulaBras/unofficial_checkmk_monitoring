import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/main.dart';
import '/screens/dashboard/dashboard.dart';
import '/screens/main/HostScreen.dart';
import '/screens/main/ServiceScreen.dart';
import '/services/battery_optimization_service.dart';
import '/widgets/appBarWidget.dart';
import '/widgets/bottomNavigationWidget.dart';
import '/widgets/settingsDrawer.dart';

class MyHomePage extends StatefulWidget {
  static const String id = 'my_home_page';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Check battery optimization status on Android
    if (Platform.isAndroid) {
      _checkBatteryOptimization();
    }
  }
  
  Future<void> _checkBatteryOptimization() async {
    try {
      final BatteryOptimizationService batteryService = BatteryOptimizationService();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Always check battery optimization status in release mode
      bool isDisabled = await batteryService.isBatteryOptimizationDisabled();
      
      // Check if we've already requested battery optimization
      bool hasRequested = await batteryService.hasRequestedBatteryOptimization();
      
      // Check if user has chosen to skip this check
      bool skipCheck = prefs.getBool('skip_battery_optimization') ?? false;
      
      print('Battery optimization check:');
      print('- Is disabled: $isDisabled');
      print('- Has requested: $hasRequested');
      print('- Skip check: $skipCheck');
      
      // Force the battery optimization screen in release mode if not disabled
      // and not explicitly skipped by the user
      if (!isDisabled && !skipCheck) {
        // Wait for the widget to be fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushNamed(context, batteryOptimizationScreenId);
          }
        });
      } else if (isDisabled) {
        // Mark as requested if it's already disabled
        await batteryService.markBatteryOptimizationRequested();
      }
    } catch (e) {
      print('Error checking battery optimization: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyHomePageLogic(),
      child: Consumer<MyHomePageLogic>(
        builder: (context, myHomePageLogic, child) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              myHomePageLogic.handleBackButton(context);
            },
            child: Scaffold(
              appBar: AppBarWidget(
                onTapLogo: () => myHomePageLogic.navigateToMain(),
              ),
              endDrawer: SettingsDrawer(),
              body: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    myHomePageLogic.updateCurrentIndex(index),
                children: [
                  DashboardScreen(),
                  ServiceScreen(),
                  HostScreen(),
                ],
              ),
              bottomNavigationBar: BottomNavigationWidget(
                currentIndex: myHomePageLogic.currentIndex,
                onItemTapped: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  myHomePageLogic.handleBottomNavigation(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class MyHomePageLogic extends ChangeNotifier {
  int _currentIndex = 0;

  MyHomePageLogic() {
    loadStartIndex();
  }

  int get currentIndex => _currentIndex;

  void updateCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void handleBottomNavigation(int index) {
    updateCurrentIndex(index);
    updateStartIndex(index);
  }

  void navigateToMain() {
    updateCurrentIndex(0);
  }

  Future<int> loadStartIndex() async {
    // Always default to Dashboard (index 0) when the app starts
    _currentIndex = 0;
    notifyListeners();
    return _currentIndex;
  }

  Future<void> updateStartIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_index', index);
    notifyListeners();
  }

  Future<void> handleBackButton(BuildContext context) async {
    if (_currentIndex != 0) {
      // If not on the dashboard, navigate to the dashboard
      updateCurrentIndex(0);
    } else {
      // If on the dashboard, show a dialog to confirm minimization
      bool? shouldMinimize = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Minimize App'),
          content: Text('Do you want to minimize the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldMinimize == true) {
        // Minimize the app
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      }
    }
  }
}
