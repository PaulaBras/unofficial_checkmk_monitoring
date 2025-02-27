import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A notifier for theme changes.
class ThemeNotifier with ChangeNotifier {
  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  /// Creates a new ThemeNotifier instance.
  ThemeNotifier() {
    _loadFromPrefs();
  }

  /// Toggles the theme between light and dark.
  toggleTheme() {
    _darkTheme = !_darkTheme;
    _saveToPrefs();
    notifyListeners();
  }

  /// Loads the theme preference from SharedPreferences.
  _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkTheme = prefs.getBool('darkTheme') ?? false;
    notifyListeners();
  }

  /// Saves the theme preference to SharedPreferences.
  _saveToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkTheme', _darkTheme);
  }
}
