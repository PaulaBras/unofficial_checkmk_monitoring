import 'package:flutter/material.dart';

const ColorScheme lightColorScheme = ColorScheme(
  primary: Color(0xFF15D1A0),      // Teal primary color
  onPrimary: Colors.white,          // White text on primary color
  secondary: Color(0xFF2196F3),     // Blue secondary color for contrast
  onSecondary: Colors.white,         // White text on secondary color
  error: Color(0xFFD32F2F),         // More defined error color
  onError: Colors.white,             // White text on error color
  surface: Color(0xFFF5F5F5),        // Light grey surface
  onSurface: Colors.black87,         // Dark text on surface
  brightness: Brightness.light,
);

const ColorScheme darkColorScheme = ColorScheme(
  primary: Color(0xFF15D1A0),       // Teal primary color
  onPrimary: Colors.white,           // White text on primary color
  secondary: Color(0xFF2196F3),      // Blue secondary color for contrast
  onSecondary: Colors.white,          // White text on secondary color
  error: Color(0xFFEF5350),          // Softer red for error
  onError: Colors.white,              // White text on error color
  surface: Color(0xFF121212),         // Very dark surface
  onSurface: Colors.white,            // White text on surface
  brightness: Brightness.dark,
);
