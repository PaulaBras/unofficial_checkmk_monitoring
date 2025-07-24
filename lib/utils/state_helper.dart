import 'package:flutter/material.dart';
import '../utils/api_constants.dart';

class StateHelper {
  static String getHostStateName(int state) {
    return ApiConstants.hostStates[state] ?? 'Unknown';
  }

  static String getServiceStateName(int state) {
    return ApiConstants.serviceStates[state] ?? 'Unknown';
  }

  static Color getStateColor(String stateName) {
    final colorHex = ApiConstants.stateColors[stateName] ?? '#6c757d';
    return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
  }

  static IconData getStateIcon(String stateName) {
    switch (stateName) {
      case 'OK':
        return Icons.check_circle;
      case 'Warning':
        return Icons.warning;
      case 'Critical':
      case 'Down':
        return Icons.error;
      case 'Unreachable':
      case 'Unknown':
        return Icons.help;
      default:
        return Icons.help;
    }
  }

  static Widget buildStateChip(String stateName) {
    return Chip(
      label: Text(
        stateName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: getStateColor(stateName),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static Widget buildStateIcon(String stateName, {double size = 24.0}) {
    return Icon(
      getStateIcon(stateName),
      color: getStateColor(stateName),
      size: size,
    );
  }
}
