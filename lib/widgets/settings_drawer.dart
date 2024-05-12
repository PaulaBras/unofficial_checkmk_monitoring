import 'package:flutter/material.dart';

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
          ListTile(
            title: Text('Help'),
            onTap: () {
              // Update the state of the app
              // Then close the drawer
              Navigator.pushNamed(context, 'help_screen');
            },
          ),
          ListTile(
            title: Text('User'),
            onTap: () {
              // Update the state of the app
              // Then close the drawer
              Navigator.pushNamed(context, 'user_screen');
            },
          ),
        ],
      ),
    );
  }
}
