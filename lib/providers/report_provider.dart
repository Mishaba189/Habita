import 'package:flutter/material.dart';
import '../models/habit_model.dart';

class ReportProvider extends ChangeNotifier {
  DateTime? _selectedDay;
  DateTime? _startDate;
  DateTime? _endDate;

  DateTime? get selectedDay => _selectedDay;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  void setDateFilter({DateTime? selectedDay, DateTime? start, DateTime? end}) {
    _selectedDay = selectedDay;
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }
  void clearFilter() {
    _selectedDay = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }
  bool _isDateInFilter(DateTime date) {
    final DateTime target = DateTime(date.year, date.month, date.day);

    if (_startDate != null && _endDate != null) {
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      return (target.isAfter(start) || target.isAtSameMomentAs(start)) &&
          (target.isBefore(end) || target.isAtSameMomentAs(end));
    } else if (_startDate != null) {
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      return target.isAtSameMomentAs(start);
    } else if (_selectedDay != null) {
      final single = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      return target.isAtSameMomentAs(single);
    } else {
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month;
    }
  }
  int getFixedTargetDays(String period, int? customPeriodDays) {
    final String cleanPeriod = period.trim().toLowerCase();

    if (cleanPeriod.contains('day') || cleanPeriod == 'daily') {
      final now = DateTime.now();
      return DateUtils.getDaysInMonth(now.year, now.month);
    } else if (cleanPeriod.contains('week') || cleanPeriod == 'weekly') {
      return 4;
    } else if (cleanPeriod.contains('month') || cleanPeriod == 'monthly') {
      return 1;
    } else if (customPeriodDays != null && customPeriodDays > 0) {
      return customPeriodDays;
    }

    final now = DateTime.now();
    return DateUtils.getDaysInMonth(now.year, now.month);
  }
  int getCompletedDaysForRange(List<DateTime> completedDates) {
    return completedDates.where((date) => _isDateInFilter(date)).length;
  }
  int calculateProgressPercentage(List<dynamic> habits) {
    if (habits.isEmpty) return 0;

    int totalTargetDaysSum = 0;
    int totalCompletedDaysSum = 0;

    for (final habit in habits) {
      final int? parsedCustomPeriodDays = habit.customPeriodDays is int
          ? habit.customPeriodDays as int?
          : int.tryParse(habit.customPeriodDays?.toString() ?? '');

      final List<DateTime> safeCompletedDates = (habit.completedDates as List?)
          ?.map((e) => e is DateTime ? e : DateTime.parse(e.toString()))
          .toList() ??
          <DateTime>[];
      final int habitTarget = getFixedTargetDays(
        habit.period ?? '',
        parsedCustomPeriodDays,
      );
      final int completed = getCompletedDaysForRange(safeCompletedDates);

      totalTargetDaysSum += habitTarget;
      totalCompletedDaysSum += completed;
    }

    if (totalTargetDaysSum == 0) return 0;
    final double ratio = (totalCompletedDaysSum / totalTargetDaysSum).clamp(0.0, 1.0);
    return (ratio * 100).round();
  }
  int getAchievedCount(List<dynamic> habits) {
    int achieved = 0;

    for (final habit in habits) {
      final int? parsedCustomPeriodDays = habit.customPeriodDays is int
          ? habit.customPeriodDays as int?
          : int.tryParse(habit.customPeriodDays?.toString() ?? '');

      final List<DateTime> safeCompletedDates = (habit.completedDates as List?)
          ?.map((e) => e is DateTime ? e : DateTime.parse(e.toString()))
          .toList() ??
          <DateTime>[];

      final int habitTarget = getFixedTargetDays(
        habit.period ?? '',
        parsedCustomPeriodDays,
      );

      final int completed = getCompletedDaysForRange(safeCompletedDates);

      if (habitTarget > 0 && completed >= habitTarget) {
        achieved++;
      }
    }
    return achieved;
  }
  int getUnachievedCount(List<dynamic> habits) {
    return habits.length - getAchievedCount(habits);
  }
  bool isHabitActiveInRange(HabitModel habit) {
    final DateTime createdAt = habit.createdAt;

    final List<DateTime> safeCompletedDates = habit.completedDates
        .map((e) => DateTime.tryParse(e))
        .whereType<DateTime>()
        .toList();

    final bool hasCompletionsInFilter =
    safeCompletedDates.any((date) => _isDateInFilter(date));
    if (hasCompletionsInFilter) return true;

    final DateTime filterEnd = _endDate ??
        _selectedDay ??
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    if (createdAt.isAfter(filterEnd)) {
      return false;
    }

    return true;
  }
  List<HabitModel> getActiveHabitsInRange(List<HabitModel> habits) {
    return habits.where((habit) => isHabitActiveInRange(habit)).toList();
  }

}