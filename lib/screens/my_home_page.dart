import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptp_4_monitoring_app/screens/main/main_screen.dart';
import 'package:ptp_4_monitoring_app/screens/monitor/monitor_screen.dart';
import 'package:ptp_4_monitoring_app/screens/customize/customize_screen.dart';
import 'package:ptp_4_monitoring_app/screens/setup/setup_screen.dart';
import 'package:ptp_4_monitoring_app/widgets/app_bar_widget.dart';
import 'package:ptp_4_monitoring_app/widgets/bottom_navigation_widget.dart';
import 'package:ptp_4_monitoring_app/widgets/settings_drawer.dart';

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
              children: const [
                MainScreen(),
                MonitorScreen(),
                CustomizeScreen(),
                SetupScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationWidget(
              currentIndex: myHomePageLogic.currentIndex,
              onItemTapped: (index) => myHomePageLogic.handleBottomNavigation(index),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              tooltip: 'Increment',
              child: const Icon(Icons.add),
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