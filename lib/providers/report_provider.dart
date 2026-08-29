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

  int getFixedTargetDays(String period, dynamic customPeriodDays) {
    final int? parsedCustom = customPeriodDays is int
        ? customPeriodDays
        : int.tryParse(customPeriodDays?.toString() ?? '');

    if (period.trim() == 'Custom' && parsedCustom != null && parsedCustom > 0) {
      return parsedCustom;
    }

    final String cleanPeriod = period.trim().toLowerCase();

    if (cleanPeriod.contains('7 day')) return 7;
    if (cleanPeriod.contains('14 day')) return 14;
    if (cleanPeriod.contains('30 day') || cleanPeriod.contains('1 month')) return 30;
    if (cleanPeriod.contains('90 day') || cleanPeriod.contains('3 month')) return 90;

    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }

    if (cleanPeriod.contains('week')) {
      return 7;
    } else if (cleanPeriod.contains('month')) {
      final now = DateTime.now();
      return DateUtils.getDaysInMonth(now.year, now.month);
    } else if (cleanPeriod.contains('year')) {
      return 365;
    }

    final now = DateTime.now();
    return DateUtils.getDaysInMonth(now.year, now.month);
  }

  int getCompletedDaysForRange(List<dynamic> completedDates) {
    return completedDates
        .map((e) => _parseToDate(e))
        .whereType<DateTime>()
        .where((date) => _isDateInFilter(date))
        .length;
  }

  int calculateProgressPercentage(List<dynamic> habits) {
    if (habits.isEmpty) return 0;

    int totalTargetDaysSum = 0;
    int totalCompletedDaysSum = 0;

    for (final habit in habits) {
      final int? parsedCustomPeriodDays = habit.customPeriodDays is int
          ? habit.customPeriodDays as int?
          : int.tryParse(habit.customPeriodDays?.toString() ?? '');

      final List<dynamic> safeCompletedDates = (habit.completedDates as List?) ?? [];

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

      final List<dynamic> safeCompletedDates = (habit.completedDates as List?) ?? [];

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

    final List<DateTime> safeCompletedDates = (habit.completedDates as List?)
        ?.map((e) => _parseToDate(e))
        .whereType<DateTime>()
        .toList() ??
        [];

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