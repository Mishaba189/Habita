import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/habit_model.dart';
import '../models/notification_model.dart';

import 'package:flutter/foundation.dart';

import 'dart:async';


class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NotificationModel> _notifications = [];
  List<HabitModel> _cachedHabits = [];
  bool _isLoading = false;
  Timer? _nightlyTimer;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _startPeriodicNightlyCheck();
  }

  @override
  void dispose() {
    _nightlyTimer?.cancel();
    super.dispose();
  }

  /// Periodically evaluates reminders (e.g., at 10:00 PM / 22:00)
  void _startPeriodicNightlyCheck() {
    _nightlyTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final now = DateTime.now();
      if (now.hour >= 22 && _cachedHabits.isNotEmpty) {
        evaluateHabitNotifications(_cachedHabits);
      }
    });
  }

  /// Update cached habits from your HabitProvider or Home Screen
  void updateHabits(List<HabitModel> habits) {
    _cachedHabits = habits;
    evaluateHabitNotifications(_cachedHabits);
  }

  /// Fetch user notifications sorted by latest first
  Future<void> fetchNotifications() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final docs = snapshot.docs;
      docs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      _notifications = docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification to Firestore
  Future<void> addNotification({
    required String type,
    required String title,
    required String message,
    required String status,
    required bool isSuccess,
    String? habitId,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final docRef = _firestore.collection('notifications').doc();
      final notification = NotificationModel(
        id: docRef.id,
        userId: currentUser.uid,
        type: type,
        title: title,
        message: message,
        status: status,
        isSuccess: isSuccess,
        isRead: false,
        createdAt: DateTime.now(),
        habitId: habitId,
      );

      await docRef.set(notification.toMap());
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding notification: $e");
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final existing = _notifications[index];
        _notifications[index] = NotificationModel(
          id: existing.id,
          userId: existing.userId,
          type: existing.type,
          title: existing.title,
          message: existing.message,
          status: existing.status,
          isSuccess: existing.isSuccess,
          isRead: true,
          createdAt: existing.createdAt,
          habitId: existing.habitId,
        );
        notifyListeners();
      }

      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          message: n.message,
          status: n.status,
          isSuccess: n.isSuccess,
          isRead: true,
          createdAt: n.createdAt,
          habitId: n.habitId,
        );
      }).toList();
      notifyListeners();

      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking all read: $e");
    }
  }

  int _getPeriodDays(String period, String? customDays) {
    final String p = period.toLowerCase();
    if (p.contains('7 day') || p.contains('weekly')) return 7;
    if (p.contains('14 day')) return 14;
    if (p.contains('30 day') || p.contains('1 month') || p.contains('monthly')) return 30;
    if (p.contains('90 day') || p.contains('3 month')) return 90;
    if (p.contains('custom') && customDays != null) {
      return int.tryParse(customDays) ?? 30;
    }
    return 30;
  }

  String _formatDateKey(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }


  Future<void> evaluateHabitNotifications(List<HabitModel> habits) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null || habits.isEmpty) return;

    _cachedHabits = habits;
    final DateTime now = DateTime.now();
    final String todayKey = _formatDateKey(now);

    for (var habit in habits) {
      if (habit.id == null) continue;

      final int targetDays = _getPeriodDays(habit.period, habit.customPeriodDays);
      final DateTime createdAtDate = DateTime(
        habit.createdAt.year,
        habit.createdAt.month,
        habit.createdAt.day,
      );
      final DateTime endDate = createdAtDate.add(Duration(days: targetDays));
      final String endDateKey = _formatDateKey(endDate);
      final bool isTodayCompleted = habit.completedDates.contains(todayKey);

      // Dynamic helper to verify if today's notification of a specific type already exists
      bool hasNotificationToday(String type) {
        return _notifications.any((n) =>
        n.type == type &&
            n.habitId == habit.id &&
            _formatDateKey(n.createdAt) == todayKey);
      }

      // --- 1. Target End Date Reminder ---
      if (endDateKey == todayKey && !hasNotificationToday('target_date_reminder')) {
        await addNotification(
          type: 'target_date_reminder',
          title: 'Goal Target Today! ⏳',
          message: 'Today is the final day to complete your habit "${habit.habitName}".',
          status: 'Pending',
          isSuccess: false,
          habitId: habit.id,
        );
      }

      // --- 2. 10:00 PM Daily Uncompleted Habit Reminder ---
      final bool isTimeForReminder = (now.hour > 16) || (now.hour == 16 && now.minute >= 41);

      if (isTimeForReminder && !isTodayCompleted && !hasNotificationToday('nightly_missed_reminder')) {
        await addNotification(
          type: 'nightly_missed_reminder',
          title: 'Uncompleted Habit Reminder 🌙',
          message: 'You haven\'t marked "${habit.habitName}" as complete today. Finish it before the day ends!',
          status: 'Pending',
          isSuccess: false,
          habitId: habit.id,
        );
      }

      // --- 3. Goal Completion Evaluation ---
      final bool alreadyEvaluated = _notifications.any(
            (n) => n.type == 'goal_completed' && n.habitId == habit.id,
      );

      if (!alreadyEvaluated) {
        final int totalCompleted = habit.completedDates.length;
        final bool reachedTarget = totalCompleted >= targetDays;
        final bool isPastEndDate = now.isAfter(endDate.add(const Duration(days: 1)));

        if (reachedTarget) {
          await addNotification(
            type: 'goal_completed',
            title: 'Goal Achieved! 🎉',
            message: 'Congratulations! You successfully completed your goal "${habit.goal.isNotEmpty ? habit.goal : habit.habitName}" with $totalCompleted/$targetDays days marked.',
            status: 'Achieved',
            isSuccess: true,
            habitId: habit.id,
          );
        } else if (isPastEndDate) {
          await addNotification(
            type: 'goal_completed',
            title: 'Goal Time Expired ⌛',
            message: 'The target date for "${habit.goal.isNotEmpty ? habit.goal : habit.habitName}" has passed. Completed: $totalCompleted of $targetDays target days.',
            status: 'Unachieved',
            isSuccess: false,
            habitId: habit.id,
          );
        }
      }
    }
  }

  Future<void> checkEndingHabits(List<HabitModel> habits) async {
    await evaluateHabitNotifications(habits);
  }
}