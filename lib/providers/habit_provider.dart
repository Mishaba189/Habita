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

  Future<bool> createHabit({
    required String goal,
    required String habitName,
    required String period,
    required String customPeriodDays,
    required String habitType,
    required Set<String> specificDays,
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

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

}