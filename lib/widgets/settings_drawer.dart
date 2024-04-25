import 'package:flutter/material.dart';

class SettingsDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text('Settings'),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          ListTile(
            title: Text('Help'),
            onTap: () {
              // Update the state of the app
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('User'),
            onTap: () {
              // Update the state of the app
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
