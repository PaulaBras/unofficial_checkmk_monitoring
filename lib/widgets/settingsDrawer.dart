import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import '../screens/user/user.dart';
import '../screens/user/loginScreen.dart';
import '../screens/help/help.dart';
import '../services/authService.dart';
import '../services/secureStorage.dart';
import '../services/apiRequest.dart';
import '../colors.dart';

class SettingsDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: lightColorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'images/checkmk-logo-white.svg',
                  height: 80,
                  width: 80,
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: lightColorScheme.primary),
            title: Text('Settings'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => UserScreen(fromDrawer: true)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: lightColorScheme.primary),
            title: Text('Help'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => HelpScreen(fromDrawer: true)),
              );
            },
          ),
          if (Platform.isAndroid)
            ListTile(
              leading:
                  Icon(Icons.battery_alert, color: lightColorScheme.primary),
              title: Text('Battery Optimization'),
              onTap: () {
                Navigator.of(context).pushNamed(batteryOptimizationScreenId);
              },
            ),
          ListTile(
            leading: Icon(Icons.logout, color: lightColorScheme.primary),
            title: Text('Logout'),
            onTap: () async {
              var secureStorage = SecureStorage();
              var apiRequest = ApiRequest();
              var authService =
                  AuthenticationService(secureStorage, apiRequest);

              final shouldGoToLogin = await authService.logout();

              if (shouldGoToLogin) {
                // No more connections, go to login screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } else {
                // Switched to another connection, refresh current screen
                Navigator.of(context).pop(); // Close drawer
                // The app will automatically use the new active connection
              }
            },
          ),
        ],
      ),
    );
  }
}
