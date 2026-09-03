import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import 'habit_provider.dart';

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

  DateTime? _parseToDate(dynamic entry) {
    if (entry == null) return null;
    if (entry is DateTime) {
      return DateTime(entry.year, entry.month, entry.day);
    }
    final String str = entry.toString().trim();
    if (str.isEmpty) return null;

    final parts = str.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2].split('T')[0]); // Strips time if present
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(str);
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



  int getCompletedDaysForRange(List<dynamic> completedDates) {
    return completedDates
        .map((e) => _parseToDate(e))
        .whereType<DateTime>()
        .where((date) => _isDateInFilter(date))
        .length;
  }

  int calculateProgressPercentage(
      List<dynamic> habits,
      HabitProvider habitProvider,
      ) {
    if (habits.isEmpty) return 0;

    int totalTargetDaysSum = 0;
    int totalCompletedDaysSum = 0;

    for (final habit in habits) {
      final List<dynamic> safeCompletedDates =
          (habit.completedDates as List?) ?? [];

      final int habitTarget =
      habitProvider.calculateTargetDays(habit);

      final int completed =
      getCompletedDaysForRange(safeCompletedDates);

      totalTargetDaysSum += habitTarget;
      totalCompletedDaysSum += completed;
    }

    if (totalTargetDaysSum == 0) return 0;

    final double ratio =
    (totalCompletedDaysSum / totalTargetDaysSum)
        .clamp(0.0, 1.0);

    return (ratio * 100).round();
  }

  int getAchievedCount(
      List<dynamic> habits,
      HabitProvider habitProvider,
      ) {
    int achieved = 0;

    for (final habit in habits) {
      final List<dynamic> safeCompletedDates =
          (habit.completedDates as List?) ?? [];

      final int habitTarget =
      habitProvider.calculateTargetDays(habit);

      final int completed =
      getCompletedDaysForRange(safeCompletedDates);

      if (habitTarget > 0 && completed >= habitTarget) {
        achieved++;
      }
    }

    return achieved;
  }



  int getUnachievedCount(
      List<dynamic> habits,
      HabitProvider habitProvider,
      ) {
    return habits.length -
        getAchievedCount(habits, habitProvider);
  }
  bool isHabitActiveInRange(HabitModel habit) {
    // Truncate time off createdAt to evaluate pure calendar dates
    final DateTime createdDateOnly = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );

    // 1. If the habit has completion logs within the selected filter, show it
    final List<DateTime> safeCompletedDates = (habit.completedDates as List?)
        ?.map((e) => _parseToDate(e))
        .whereType<DateTime>()
        .toList() ??
        [];

    final bool hasCompletionsInFilter =
    safeCompletedDates.any((date) => _isDateInFilter(date));
    if (hasCompletionsInFilter) return true;

    // 2. Normalize filter bounds to cover the full end-of-day (23:59:59)
    final now = DateTime.now();
    final DateTime filterEnd;

    if (_endDate != null) {
      filterEnd = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
    } else if (_selectedDay != null) {
      filterEnd = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, 23, 59, 59);
    } else {
      // Current Month end date set to last second of the month
      filterEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    // Goal created today will now properly evaluate: 2026-08-31 00:00 <= 2026-08-31 23:59
    if (createdDateOnly.isAfter(filterEnd)) {
      return false;
    }

    return true;
  }

  List<HabitModel> getActiveHabitsInRange(List<HabitModel> habits) {
    return habits.where((habit) => isHabitActiveInRange(habit)).toList();
  }


}