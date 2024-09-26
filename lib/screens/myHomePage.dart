import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/screens/dashboard/dashboard.dart';
import '/screens/main/HostScreen.dart';
import '/screens/main/ServiceScreen.dart';
import '/screens/setup/setupScreen.dart';
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
                  SetupScreen(),
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentIndex = prefs.getInt('start_index') ?? 0;
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
