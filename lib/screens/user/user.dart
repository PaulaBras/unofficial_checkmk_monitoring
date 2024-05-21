import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:ptp_4_monitoring_app/screens/myHomePage.dart';
import 'package:ptp_4_monitoring_app/screens/user/loginScreen.dart'; // Import the login screen
import 'package:ptp_4_monitoring_app/services/themeNotifier.dart';
import 'package:ptp_4_monitoring_app/widgets/appBarWidget.dart';

import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest(); // Create an ApiRequest instance
  late AuthenticationService authService; // Define authService

  void navigateToHomeScreen() {
    Navigator.pushNamed(context, 'home_screen');
  }

  @override
  void initState() {
    super.initState();
    authService = AuthenticationService(
        secureStorage, apiRequest); // Initialize authService
    // ... rest of your code
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final myHomePageLogic = MyHomePageLogic();

    return Scaffold(
      appBar: AppBarWidget(
        onTapLogo: () => myHomePageLogic.navigateToMain(),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(
              'User interface',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: SvgPicture.asset(
              'images/icon_topic_user_interface.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.surface, BlendMode.srcIn),
            ),
          ),
          // Headline
          SwitchListTile(
            title: Text('Dark Theme'),
            value: themeNotifier.darkTheme,
            onChanged: (value) {
              setState(() {
                themeNotifier.toggleTheme();
              });
            },
          ),
          ListTile(
            title: Text(
              'User profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: Image.asset(
              'images/icon_topic_profile.png',
              width: 30,
              height: 30,
            ),
          ),
          GestureDetector(
            onTap: () async {
              await authService
                  .logout(navigateToHomeScreen); // Call the logout function
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) =>
                        LoginScreen()), // Navigate to the login screen
              );
            },
            child: ListTile(title: Text('Logout')),
          ),
        ],
      ),
    );
  }
}
