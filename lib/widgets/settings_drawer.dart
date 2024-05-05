import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/screens/setup/HelpPage.dart';
import 'package:ptp_4_monitoring_app/screens/setup/UserPage.dart';

class SettingsDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          DrawerHeader(
            child: Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help'),
                  onTap: () {
                    // Navigate to the HelpPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HelpPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('User'),
                  onTap: () {
                    // Navigate to the UserConfig
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserConfig()),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.secondary,
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Implement logout
              },
            ),
          ),
        ],
      ),
    );
  }
}