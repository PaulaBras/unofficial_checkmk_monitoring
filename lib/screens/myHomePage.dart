import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyHomePageLogic(),
      child: Consumer<MyHomePageLogic>(
        builder: (context, myHomePageLogic, child) {
          return Scaffold(
            appBar: AppBarWidget(
              onTapLogo: () => myHomePageLogic.navigateToMain(),
            ),
            endDrawer: SettingsDrawer(),
            body: IndexedStack(
              index: myHomePageLogic.currentIndex,
              children: [
                DashboardScreen(),
                ServiceScreen(),
                HostScreen(),
                SetupScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationWidget(
              currentIndex: myHomePageLogic.currentIndex,
              onItemTapped: (index) =>
                  myHomePageLogic.handleBottomNavigation(index),
            ),
          );
        },
      ),
    );
  }
}

class MyHomePageLogic extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void updateCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void handleBottomNavigation(int index) {
    updateCurrentIndex(index);
  }

  void navigateToMain() {
    updateCurrentIndex(0);
  }
}
