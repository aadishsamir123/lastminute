import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';

import '../models/homework.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();
  bool _hasPermission = false;

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false; // Not supported on web

    try {
      var permissionsGranted = await _deviceCalendar.hasPermissions();
      if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
        permissionsGranted = await _deviceCalendar.requestPermissions();
      }
      _hasPermission = permissionsGranted.data ?? false;
      return _hasPermission;
    } catch (e) {
      return false;
    }
  }

  Future<List<Calendar>> getCalendars() async {
    if (kIsWeb || !_hasPermission) return [];

    try {
      final calendarsResult = await _deviceCalendar.retrieveCalendars();
      return calendarsResult.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addHomeworkToCalendar(
    Homework homework,
    String calendarId,
  ) async {
    if (kIsWeb || !_hasPermission) return false;

    try {
      final event = Event(
        calendarId,
        title: homework.title,
        description: homework.description,
        start: TZDateTime.from(homework.dueDate, local),
        end: TZDateTime.from(
          homework.dueDate.add(const Duration(hours: 1)),
          local,
        ),
        location: homework.subject,
      );

      final result = await _deviceCalendar.createOrUpdateEvent(event);
      return result?.isSuccess ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Event>> getEventsForDate(String calendarId, DateTime date) async {
    if (kIsWeb || !_hasPermission) return [];

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final eventsResult = await _deviceCalendar.retrieveEvents(
        calendarId,
        RetrieveEventsParams(startDate: startOfDay, endDate: endOfDay),
      );

      return eventsResult.data ?? [];
    } catch (e) {
      return [];
    }
  }
}
