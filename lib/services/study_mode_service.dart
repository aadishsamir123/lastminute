import 'dart:async';
import 'dart:io';

import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';

class StudyModeService {
  static final StudyModeService _instance = StudyModeService._internal();
  factory StudyModeService() => _instance;
  StudyModeService._internal();

  bool _isStudyModeActive = false;
  Timer? _studyTimer;
  DateTime? _studyStartTime;
  Duration _studyDuration = Duration.zero;

  bool get isStudyModeActive => _isStudyModeActive;
  Duration get studyDuration => _studyDuration;
  DateTime? get studyStartTime => _studyStartTime;

  // Start study mode with timer
  void startStudyMode(Duration duration, {VoidCallback? onComplete}) {
    if (kIsWeb) return; // Not supported on web

    _isStudyModeActive = true;
    _studyStartTime = DateTime.now();
    _studyDuration = duration;

    _studyTimer?.cancel();
    _studyTimer = Timer(duration, () {
      stopStudyMode();
      onComplete?.call();
    });
  }

  void stopStudyMode() {
    _isStudyModeActive = false;
    _studyTimer?.cancel();
    _studyTimer = null;
    _studyStartTime = null;
    _studyDuration = Duration.zero;
  }

  Duration getRemainingTime() {
    if (!_isStudyModeActive || _studyStartTime == null) {
      return Duration.zero;
    }

    final elapsed = DateTime.now().difference(_studyStartTime!);
    final remaining = _studyDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Get app usage stats (Android only)
  Future<List<AppUsageInfo>> getAppUsageStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return [];

    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 1));
      final end = endDate ?? now;

      final List<AppUsageInfo> infos = await AppUsage().getAppUsage(start, end);
      return infos;
    } catch (e) {
      return [];
    }
  }

  // Get today's study time based on app usage
  Future<Duration> getTodayStudyTime() async {
    if (kIsWeb || !Platform.isAndroid) return Duration.zero;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final infos = await getAppUsageStats(startDate: startOfDay, endDate: now);

      // Filter for study-related apps or this app
      int totalMinutes = 0;
      for (var info in infos) {
        if (info.packageName.contains('lastminute')) {
          totalMinutes += info.usage.inMinutes;
        }
      }

      return Duration(minutes: totalMinutes);
    } catch (e) {
      return Duration.zero;
    }
  }

  void dispose() {
    _studyTimer?.cancel();
  }
}
