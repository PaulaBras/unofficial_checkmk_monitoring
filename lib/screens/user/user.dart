import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../services/apiRequest.dart';
import '../../services/authService.dart';
import '../../services/secureStorage.dart';
import '/screens/myHomePage.dart';
import '/screens/user/loginScreen.dart';
import '/services/themeNotifier.dart';
import '/widgets/appBarWidget.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  var secureStorage = SecureStorage();
  var apiRequest = ApiRequest(); // Create an ApiRequest instance
  late AuthenticationService authService; // Define authService

  Map<String, int> pageNameToIndex = {
    'Dashboard': 0,
    'Service': 1,
    'Host': 2,
    'Setup': 3,
  };

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
                  Theme.of(context).colorScheme.primary, BlendMode.srcIn),
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
            title: Text('Set Start Page'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Text('Choose Start Page'),
                    children: pageNameToIndex.keys.map((pageName) {
                      return SimpleDialogOption(
                        child: Text(pageName),
                        onPressed: () {
                          myHomePageLogic
                              .updateStartIndex(pageNameToIndex[pageName]!);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              );
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
