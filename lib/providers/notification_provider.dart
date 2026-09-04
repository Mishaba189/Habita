import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit_model.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  List<NotificationModel> _notifications = [];
  List<HabitModel> _cachedHabits = [];
  bool _isLoading = false;
  Timer? _nightlyTimer;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  // Toggle this to TRUE when testing short-term schedule triggers
  static const bool _isTestingReminders = true;

  static const int _reminderHour = _isTestingReminders ? 15 : 22;
  static const int _reminderMinute = _isTestingReminders ? 50 : 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  /// Getter: Excludes legacy/secondary creation types from unread count
  int get unreadCount {
    return _notifications.where((item) {
      final type = item.type.toLowerCase().trim();
      final isExcluded =
          type == 'new_habit_created' || type == 'new_goal_created';
      return !item.isRead && !isExcluded;
    }).length;
  }

  late final Future<void> _initialization;

  NotificationProvider() {
    _initialization = _initLocalNotifications();
    _startPeriodicNightlyCheck();
    initNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _nightlyTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocalNotifications() async {
    tz_data.initializeTimeZones();

    try {
      final dynamic currentTimeZone = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = currentTimeZone is String
          ? currentTimeZone
          : currentTimeZone.name ?? currentTimeZone.toString();

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'habit_app_notifications_v1',
      'App Notifications',
      description: 'Alerts for habit reminders, goals, and completions',
      importance: Importance.max,
    );

    await androidImplementation?.createNotificationChannel(channel);
    await androidImplementation?.requestExactAlarmsPermission();
    await androidImplementation?.requestNotificationsPermission();
  }

  /// Trigger a direct system tray alert on the device
  Future<void> _showSystemNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 500]);

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_app_notifications_v1',
          'App Notifications',
          channelDescription:
          'Alerts for habit reminders, goals, and completions',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          playSound: true,
          channelShowBadge: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        ),
      ),
    );
  }

  /// Centralized method to handle adding notifications (DB + Phone Taskbar)
  Future<void> addNotification({
    required String customDocId,
    required String type,
    required String title,
    required String message,
    required String status,
    required bool isSuccess,
    String? habitId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool('push_notifications_enabled') ?? true;

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (_notifications.any((n) => n.id == customDocId)) return;

    final docRef = _firestore.collection('notifications').doc(customDocId);

    final notification = NotificationModel(
      id: customDocId,
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

    _notifications.insert(0, notification);
    notifyListeners();

    try {
      await docRef.set(notification.toMap());
    } catch (e) {
      debugPrint("Error adding notification to Firestore: $e");
    }

    if (isEnabled) {
      try {
        final int notificationId = customDocId.hashCode.abs();
        await _showSystemNotification(
          id: notificationId,
          title: title,
          body: message,
        );
      } catch (e) {
        debugPrint("Error displaying phone taskbar notification: $e");
      }
    } else {
      debugPrint("Notifications disabled: Skipping system tray popup for doc $customDocId");
    }
  }

  /// Calculates the habit's target end date
  DateTime _calculateEndDate(HabitModel habit) {
    final int targetDays = _getPeriodDays(habit.period, habit.customPeriodDays);
    final DateTime createdAtDate = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    return createdAtDate.add(Duration(days: targetDays - 1));
  }

  Future<void> scheduleUpcomingHabitReminders(HabitModel habit) async {
    await _initialization;
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled =
        prefs.getBool('push_notifications_enabled') ?? true;

    if (!isEnabled || habit.id == null) return;

    // Cancel old reminders for this habit first.
    await cancelHabitReminder(habit.id!);

    final now = tz.TZDateTime.now(tz.local);
    final DateTime endDate = _calculateEndDate(habit);

    for (int i = 0; i < 30; i++) {
      final DateTime date = DateTime.now().add(Duration(days: i));

      // 1. Don't schedule past the habit's end date.
      final DateTime checkDateOnly = DateTime(date.year, date.month, date.day);
      final DateTime endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      if (checkDateOnly.isAfter(endDateOnly)) {
        continue;
      }

      // 2. Don't schedule days that are not target days.
      if (!_isHabitApplicableToday(habit, date)) {
        continue;
      }

      final String dateKey = _formatDateKey(date);

      // 3. Don't schedule if already completed.
      if (habit.completedDates.contains(dateKey)) {
        continue;
      }

      final tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        _reminderHour,
        _reminderMinute,
      );

      if (scheduledDate.isBefore(now)) {
        continue;
      }

      final int notificationId = '${habit.id}_$dateKey'.hashCode.abs();

      await _localNotifications.zonedSchedule(
        id: notificationId,
        title: 'Uncompleted Habit Reminder 🌙',
        body: 'You haven\'t marked "${habit.habitName}" as complete today. Finish it before the day ends!',
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_app_notifications_v1',
            'App Notifications',
            channelDescription:
            'Alerts for habit reminders, goals, and completions',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            channelShowBadge: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
        'Scheduled ${habit.habitName} reminder for $scheduledDate',
      );
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    final int oldNotificationId = habitId.hashCode.abs();
    await _localNotifications.cancel(id: oldNotificationId);

    for (int i = 0; i < 30; i++) {
      final DateTime date = DateTime.now().add(Duration(days: i));
      final String dateKey = _formatDateKey(date);
      final int notificationId = '${habitId}_$dateKey'.hashCode.abs();

      await _localNotifications.cancel(id: notificationId);
    }
  }

  Future<void> cancelHabitReminderForDate(
      String habitId,
      DateTime date,
      ) async {
    final dateKey = _formatDateKey(date);
    final notificationId = '${habitId}_$dateKey'.hashCode.abs();

    await _localNotifications.cancel(id: notificationId);
  }

  void initNotificationListener() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _notificationSubscription?.cancel();

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen(
          (snapshot) {
        final docs = snapshot.docs;
        docs.sort((a, b) {
          final aTime =
              (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime =
              (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        _notifications = docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList();

        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error listening to notifications: $error");
      },
    );
  }

  void _startPeriodicNightlyCheck() {
    _nightlyTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final now = DateTime.now();
      if (now.hour == 0 && _cachedHabits.isNotEmpty) {
        evaluateHabitNotifications(_cachedHabits);
      }
    });
  }

  Future<void> updateHabits(List<HabitModel> habits) async {
    _cachedHabits = habits;

    for (final habit in habits) {
      await scheduleUpcomingHabitReminders(habit);
    }

    await evaluateHabitNotifications(_cachedHabits);
  }
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
        final aTime =
            (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime =
            (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
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
    if (p.contains('30 day') || p.contains('1 month') || p.contains('monthly')) {
      return 30;
    }
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

    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool('push_notifications_enabled') ?? true;

    if (!isEnabled) {
      debugPrint("Global push notifications disabled. Clearing pending schedules.");
      await cancelAllNotifications();
      return;
    }

    _cachedHabits = habits;
    final DateTime now = DateTime.now();
    final String todayKey = _formatDateKey(now);

    for (var habit in habits) {
      if (habit.id == null) continue;

      final int targetDays = _getPeriodDays(habit.period, habit.customPeriodDays);
      final DateTime endDate = _calculateEndDate(habit);
      final String endDateKey = _formatDateKey(endDate);
      final bool isTodayCompleted = habit.completedDates.contains(todayKey);

      bool hasNotificationToday(String type) {
        return _notifications.any((n) =>
        n.type == type &&
            n.habitId == habit.id &&
            _formatDateKey(n.createdAt) == todayKey);
      }

      final bool isApplicableToday = _isHabitApplicableToday(habit, now);

      if (!isApplicableToday) {
        await cancelHabitReminderForDate(habit.id!, now);
        debugPrint('Skipping reminder for ${habit.habitName} - today is not an applicable day.');
      } else if (isTodayCompleted) {
        await cancelHabitReminderForDate(habit.id!, now);
        debugPrint('Skipping reminder for ${habit.habitName} - already completed today.');
      } else {
        final bool isTimeForReminder =
            (now.hour > _reminderHour) ||
                (now.hour == _reminderHour && now.minute >= _reminderMinute);

        if (isTimeForReminder && !hasNotificationToday('nightly_missed_reminder')) {
          final String docId = "nightly_missed_reminder_${habit.id}_$todayKey";

          await addNotification(
            customDocId: docId,
            type: 'nightly_missed_reminder',
            title: 'Uncompleted Habit Reminder 🌙',
            message:
            'You haven\'t marked "${habit.habitName}" as complete today. Finish it before the day ends!',
            status: 'Pending',
            isSuccess: false,
            habitId: habit.id,
          );
        }
      }

      // Goal Evaluation
      final bool alreadyEvaluated = _notifications.any(
            (n) => (n.type == 'goal_completed' || n.type == 'goal_expired') && n.habitId == habit.id,
      );

      if (!alreadyEvaluated) {
        final int totalCompleted = habit.completedDates.length;
        final double percentageVal = (totalCompleted / targetDays) * 100;
        final String progressPercent = "${percentageVal.toStringAsFixed(0)}%";
        final String goalTitle = habit.goal.isNotEmpty ? habit.goal : habit.habitName;

        if (endDateKey == todayKey && isTodayCompleted) {
          final bool is100Percent = totalCompleted >= targetDays;
          final String docId = "goal_completed_${habit.id}_$todayKey";

          await addNotification(
            customDocId: docId,
            type: 'goal_completed',
            title: is100Percent ? 'Goal Fully Achieved! 🎉' : 'Goal Period Ended 🎯',
            message:
            'Today was your target date for "$goalTitle". You completed $totalCompleted of $targetDays days ($progressPercent progress)!',
            status: is100Percent ? 'Achieved' : 'Partial',
            isSuccess: is100Percent,
            habitId: habit.id,
          );
        } else if (now.isAfter(endDate.add(const Duration(days: 1))) ||
            (endDateKey == todayKey && now.hour == 0 && !isTodayCompleted)) {
          final String docId = "goal_expired_${habit.id}_$todayKey";

          await addNotification(
            customDocId: docId,
            type: 'goal_expired',
            title: 'Goal Time Expired ⌛',
            message:
            'The target period for "$goalTitle" has ended. You completed $totalCompleted of $targetDays days ($progressPercent progress).',
            status: 'Expired',
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

  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint("All scheduled push notifications cancelled successfully.");
    } catch (e) {
      debugPrint("Error cancelling notifications: $e");
    }
  }

  bool _isHabitApplicableToday(HabitModel habit, DateTime date) {
    final String type = habit.habitType.trim().toLowerCase();

    if (type.contains('weekday')) {
      return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
    }

    if (type.contains('weekend')) {
      return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    }

    if (type.contains('specific')) {
      final String dayName = _getDayName(date.weekday);
      return (habit.specificDays ?? []).any(
            (day) => day.trim().toLowerCase() == dayName.toLowerCase(),
      );
    }

    return true;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}