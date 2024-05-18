import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../services/secureStorage.dart';

class AreNotificationsActive {
  var secureStorage = SecureStorage();
  TimeOfDay _workingHoursStart = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workingHoursEnd = TimeOfDay(hour: 17, minute: 0);
  bool _notifyDuringWorkingHours = true;
  bool _notifyDuringOffHours = false;
  List<bool> _selectedDays = List<bool>.filled(7, false);
  String _selectedTimeZone = 'Europe/Berlin';

  Future<void> _loadSettings() async {
    _selectedTimeZone =
        await secureStorage.readSecureData('timeZone') ?? 'Europe/Berlin';
    final startHour = int.parse(
        await secureStorage.readSecureData('workingHoursStartHour') ?? '8');
    final startMinute = int.parse(
        await secureStorage.readSecureData('workingHoursStartMinute') ?? '0');
    _workingHoursStart = TimeOfDay(hour: startHour, minute: startMinute);

    final endHour = int.parse(
        await secureStorage.readSecureData('workingHoursEndHour') ?? '18');
    final endMinute = int.parse(
        await secureStorage.readSecureData('workingHoursEndMinute') ?? '0');
    _workingHoursEnd = TimeOfDay(hour: endHour, minute: endMinute);
    print(_workingHoursEnd);

    _notifyDuringWorkingHours =
        (await secureStorage.readSecureData('notifyDuringWorkingHours'))
                    ?.toLowerCase() ==
                'true' ??
            true;
    _notifyDuringOffHours =
        (await secureStorage.readSecureData('notifyDuringOffHours'))
                    ?.toLowerCase() ==
                'true' ??
            false;

    for (int i = 0; i < 7; i++) {
      _selectedDays[i] = (await secureStorage.readSecureData('selectedDay$i'))
                  ?.toLowerCase() ==
              'true' ??
          (i < 5);
    }
  }

  Future<bool> areNotificationsActive() async {
    await _loadSettings();
    final now = tz.TZDateTime.now(tz.getLocation(_selectedTimeZone));
    final currentDayOfWeek = now.weekday -
        1; // DateTime's weekday is 1-based (Monday is 1, Sunday is 7)

    // Check if the current day of the week is selected
    if (_selectedDays[currentDayOfWeek]) {
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
      final isNowDuringWorkingHours =
          (currentTime.hour > _workingHoursStart.hour ||
                  (currentTime.hour == _workingHoursStart.hour &&
                      currentTime.minute >= _workingHoursStart.minute)) &&
              (currentTime.hour < _workingHoursEnd.hour ||
                  (currentTime.hour == _workingHoursEnd.hour &&
                      currentTime.minute <= _workingHoursEnd.minute));

      // If it's during working hours, return the value of _notifyDuringWorkingHours
      // If it's not during working hours, return the value of _notifyDuringOffHours
      return isNowDuringWorkingHours
          ? _notifyDuringWorkingHours
          : _notifyDuringOffHours;
    }

    // If the current day is not selected, return the value of _notifyDuringOffHours
    return _notifyDuringOffHours;
  }
}
