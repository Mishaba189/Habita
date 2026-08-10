import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/habit_model.dart';

class GoalItem {
  final String id;
  final String title;
  final int currentProgress;
  final int totalDays;
  final String frequency;

  GoalItem({
    required this.id,
    required this.title,
    required this.currentProgress,
    required this.totalDays,
    required this.frequency,
  });

  factory GoalItem.fromFirestore(Map<String, dynamic> json, String docId) {
    return GoalItem(
      id: docId,
      title: json['goal'] ?? json['habitName'] ?? 'Untitled Goal',
      currentProgress: json['currentProgress'] ?? 0,
      totalDays: json['totalDays'] ?? 7,
      frequency: json['period'] ?? 'Everyday',
    );
  }
}

class HabitProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GoalItem> _goals = [];
  bool _isLoading = false;

  List<GoalItem> get goals => _goals;
  bool get isLoading => _isLoading;

  /// Fetch goals for the currently authenticated user
  Future<void> fetchGoals() async {
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
          .orderBy('createdAt', descending: true)
          .get();

      _goals = snapshot.docs
          .map((doc) => GoalItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching goals: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a goal by document ID and refresh local state
  Future<bool> deleteGoal(String goalId) async {
    try {
      await _firestore.collection('habits').doc(goalId).delete();
      _goals.removeWhere((item) => item.id == goalId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting goal: $e");
      return false;
    }
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
      final habit = HabitModel(
        userId: currentUser.uid,
        goal: goal,
        habitName: habitName,
        period: period,
        customPeriodDays: period == 'Custom' ? customPeriodDays : null,
        habitType: habitType,
        specificDays: habitType == 'Specific Days' ? specificDays.toList() : [],
        createdAt: DateTime.now(),
      );

      await _firestore.collection('habits').add(habit.toMap());

      // Refresh the goals list automatically after creation
      await fetchGoals();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error creating habit: $e");
      return false;
    }
  }
}