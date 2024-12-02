import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                  colorFilter: ColorFilter.mode(
                    Colors.white, 
                    BlendMode.srcIn
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: lightColorScheme.primary),
            title: Text('Settings'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => UserScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: lightColorScheme.primary),
            title: Text('Help'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => HelpScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: lightColorScheme.primary),
            title: Text('Logout'),
            onTap: () async {
              var secureStorage = SecureStorage();
              var apiRequest = ApiRequest();
              var authService = AuthenticationService(secureStorage, apiRequest);
              
              await authService.logout(() {});
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
