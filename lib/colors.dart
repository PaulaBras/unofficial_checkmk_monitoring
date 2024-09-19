import 'package:flutter/material.dart';

const ColorScheme lightColorScheme = ColorScheme(
  primary: Color(0xFF15D1A0),
  onPrimary: Colors.white,
  secondary: Color(0xFF15D1A0),
  onSecondary: Colors.white,
  error: Colors.redAccent,
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Colors.black,
  // Added onBackground color
  brightness: Brightness.light,
);

const ColorScheme darkColorScheme = ColorScheme(
  primary: Color(0xFF15D1A0),
  secondary: Color(0xFF15D1A0),
  surface: Color(0xFF1E2533),
  error: Colors.redAccent,
  onError: Colors.white,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.white,
  // Added onBackground color
  brightness: Brightness.dark,
);
