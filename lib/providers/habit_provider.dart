import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_model.dart';
import 'notification_provider.dart';

class HabitProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<HabitModel> _habits = [];
  bool _isLoading = false;

  List<HabitModel> get habits => _habits;
  List<HabitModel> get goals => _habits;
  bool get isLoading => _isLoading;

  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }
  Future<void> fetchHabits() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint("Error: No authenticated user found.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final docs = snapshot.docs;

      // Sort in memory by createdAt descending to avoid requiring a composite index
      docs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      _habits = docs
          .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching habits: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> fetchGoals() async {
    await fetchHabits();
  }
  DateTime calculateEndDate(HabitModel habit) {
    return _calculateEndDate(
      habit.createdAt,
      habit.period,
      habit.customPeriodDays,
    );
  }

  Future<bool> createHabit({
    required String goal,
    required String habitName,
    required String period,
    required String customPeriodDays,
    required String habitType,
    required Set<String> specificDays,
    NotificationProvider? notificationProvider,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint("Error: No authenticated user found.");
      return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final String timestampId = DateTime.now().millisecondsSinceEpoch.toString();
      final habit = HabitModel(
        id: timestampId,
        userId: currentUser.uid,
        goal: goal,
        habitName: habitName,
        period: period,
        customPeriodDays: period == 'Custom' ? customPeriodDays : null,
        habitType: habitType,
        specificDays: habitType == 'Specific Days' ? specificDays.toList() : [],
        createdAt: DateTime.now(),
      );
      await _firestore.collection('habits').doc(timestampId).set(habit.toMap());
      final notificationRef = _firestore.collection('notifications').doc();
      await notificationRef.set({
        'id': notificationRef.id,
        'userId': currentUser.uid,
        'type': 'new_goal_created',
        'title': 'New Habit Added 🚀',
        'message': 'Your new habit "$habitName" has been set up successfully.',
        'status': 'Active',
        'isSuccess': true,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await fetchHabits();

      if (notificationProvider != null) {
        await notificationProvider.updateHabits(_habits);
      }

      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error creating habit: $e");
      return false;
    }
  }
  /// Toggle habit completion status and sync with Firestore
  Future<void> toggleHabitCompletion(String habitId, bool newStatus) async {
    try {
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        final existing = _habits[index];
        _habits[index] = HabitModel(
          id: existing.id,
          userId: existing.userId,
          goal: existing.goal,
          habitName: existing.habitName,
          period: existing.period,
          customPeriodDays: existing.customPeriodDays,
          habitType: existing.habitType,
          specificDays: existing.specificDays,
          createdAt: existing.createdAt,
          isCompleted: newStatus,
        );
        notifyListeners();
      }

      await _firestore.collection('habits').doc(habitId).update({
        'isCompleted': newStatus,
      });
    } catch (e) {
      debugPrint("Error updating habit status: $e");
    }
  }



  /// Delete a habit/goal by ID
  Future<bool> deleteHabit(String habitId) async {
    try {
      await _firestore.collection('habits').doc(habitId).delete();
      _habits.removeWhere((item) => item.id == habitId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting habit: $e");
      return false;
    }
  }

  /// Alias method for deleteGoal
  Future<bool> deleteGoal(String goalId) async {
    return await deleteHabit(goalId);
  }

  Future<void> toggleHabitCompletionForDate(
      String habitId,
      String dateKey,
      bool newStatus, {
        NotificationProvider? notificationProvider,
      }) async {
    try {
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        final existing = _habits[index];
        List<String> updatedDates = List<String>.from(existing.completedDates ?? []);

        if (newStatus) {
          if (!updatedDates.contains(dateKey)) updatedDates.add(dateKey);
        } else {
          updatedDates.remove(dateKey);
        }

        final bool isToday = dateKey == _formatDateKey(DateTime.now());

        final updatedHabit = existing.copyWith(
          completedDates: updatedDates,
          isCompleted: isToday ? newStatus : existing.isCompleted,
        );

        _habits[index] = updatedHabit;
        notifyListeners();

        await _firestore.collection('habits').doc(habitId).update({
          'completedDates': newStatus
              ? FieldValue.arrayUnion([dateKey])
              : FieldValue.arrayRemove([dateKey]),
          if (isToday) 'isCompleted': newStatus,
        });

        // Evaluate goals immediately upon marking completion
        if (notificationProvider != null) {
          await notificationProvider.evaluateHabitNotifications(_habits);
        }
      }
    } catch (e) {
      debugPrint("Error updating habit completion date: $e");
    }
  }

  Future<bool> updateHabit({
    required String habitId,
    required String goal,
    required String habitName,
    required String period,
    required String customPeriodDays,
    required String habitType,
    required Set<String> specificDays,
    NotificationProvider? notificationProvider,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('habits').doc(habitId).update({
        'goal': goal,
        'habitName': habitName,
        'period': period,
        'customPeriodDays': customPeriodDays,
        'habitType': habitType,
        'specificDays': specificDays.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update locally in memory to reflect changes immediately in UI
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = _habits[index].copyWith(
          goal: goal,
          habitName: habitName,
          period: period,
          customPeriodDays: customPeriodDays,
          habitType: habitType,
          specificDays: specificDays.toList(),
        );
      }

      if (notificationProvider != null) {
        await notificationProvider.updateHabits(_habits);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Unified function to calculate target days/occurrences for any habit scenario
  int calculateTargetDays(HabitModel habit) {
    final DateTime startDate = habit.createdAt;

    final DateTime endDate = _calculateEndDate(
      startDate,
      habit.period,
      habit.customPeriodDays,
    );

    final String type = habit.habitType.trim().toLowerCase();

    // Weekdays (Mon-Fri)
    if (type.contains('weekday')) {
      return _countDays(
        startDate,
        endDate,
            (date) =>
        date.weekday >= DateTime.monday &&
            date.weekday <= DateTime.friday,
      );
    }

    // Weekends Only
    if (type.contains('weekend')) {
      return _countDays(
        startDate,
        endDate,
            (date) =>
        date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday,
      );
    }

    // Specific Days
    if (type.contains('specific')) {
      return _countSpecificDays(
        startDate,
        endDate,
        habit.specificDays ?? [],
      );
    }

    // Everyday
    if (type.contains('everyday')) {
      return endDate.difference(startDate).inDays + 1;
    }

    // Weekly
    if (type == 'weekly') {
      return _countWeeks(startDate, endDate);
    }

    // Monthly
    if (type == 'monthly') {
      return _countMonths(startDate, endDate);
    }

    return endDate.difference(startDate).inDays + 1;
  }

  DateTime _calculateEndDate(
      DateTime start,
      String period,
      String? customPeriodDays,
      ) {
    final String p = period.trim().toLowerCase();
    final match = RegExp(r'\d+').firstMatch(p);

    if (match != null) {
      final int number = int.parse(match.group(0)!);

      // Weeks
      if (p.contains('week')) {
        return start.add(
          Duration(days: (number * 7) - 1),
        );
      }

      // Months
      if (p.contains('month')) {
        return DateTime(
          start.year,
          start.month + number,
          start.day,
        );
      }

      // Years
      if (p.contains('year')) {
        return DateTime(
          start.year + number,
          start.month,
          start.day,
        ).subtract(
          const Duration(days: 1),
        );
      }

      // Days
      if (p.contains('day')) {
        return start.add(
          Duration(days: number - 1),
        );
      }
    }

    // Custom period
    if (p == 'custom') {
      final int days =
          int.tryParse(customPeriodDays ?? '') ?? 7;

      return start.add(
        Duration(days: days - 1),
      );
    }

    // Fallback: 7 days
    return start.add(
      const Duration(days: 6),
    );
  }

  /// Helper: Count specific selected days (e.g., Mon, Thu)
  int _countSpecificDays(DateTime start, DateTime end, List<String> specificDays) {
    return _countDays(start, end, (date) {
      String dayName = _getDayName(date.weekday);
      return specificDays.contains(dayName);
    });
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  /// Helper: Count total weeks in period
  int _countWeeks(DateTime start, DateTime end) {
    int totalDays = end.difference(start).inDays + 1;
    return (totalDays / 7).ceil();
  }

  /// Helper: Count total months in period
  int _countMonths(DateTime start, DateTime end) {
    int yearDiff = end.year - start.year;
    int monthDiff = end.month - start.month;
    int totalMonths = yearDiff * 12 + monthDiff;
    if (end.day >= start.day) totalMonths++;
    return totalMonths > 0 ? totalMonths : 1;
  }

  int _countDays(
      DateTime start,
      DateTime end,
      bool Function(DateTime) condition,
      ) {
    int count = 0;
    DateTime current = start;

    while (!current.isAfter(end)) {
      if (condition(current)) {
        count++;
      }

      current = current.add(
        const Duration(days: 1),
      );
    }

    return count;
  }
}