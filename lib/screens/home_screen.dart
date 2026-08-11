import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habita/screens/auth_screen.dart';
import 'package:habita/screens/your_goal_screen.dart';
import 'package:habita/screens/your_habit_screen.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/habit_model.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/create_habit_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';

class HabitItem {
  final String title;
  bool isCompleted;

  HabitItem({required this.title, required this.isCompleted});
}

class GoalItem {
  final String title;
  final double progressValue;
  final String progressText;
  final String frequency;

  GoalItem({
    required this.title,
    required this.progressValue,
    required this.progressText,
    required this.frequency,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Helper to format date keys for Firestore matching
  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  /// Date comparison helpers for frequency checks
  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  bool _isSameWeek(DateTime d1, DateTime d2) {
    final start1 = d1.subtract(Duration(days: d1.weekday - 1));
    final start2 = d2.subtract(Duration(days: d2.weekday - 1));
    return _isSameDay(start1, start2);
  }

  bool _isSameMonth(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month;

  DateTime? _parseDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  int _getPeriodDurationInDays(String period, String? customPeriodDays) {
    if (period.contains('7 Days')) return 7;
    if (period.contains('14 Days')) return 14;
    if (period.contains('30 Days') || period.contains('1 Month')) return 30;
    if (period.contains('90 Days') || period.contains('3 Months')) return 90;
    if (period == 'Custom' && customPeriodDays != null) {
      return int.tryParse(customPeriodDays) ?? 30;
    }
    return 365;
  }

  bool _isDateWithinPeriod(DateTime createdAt, String period, String? customPeriodDays, DateTime targetDate) {
    final startCreated = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final startTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (startTarget.isBefore(startCreated)) return false;

    final durationDays = _getPeriodDurationInDays(period, customPeriodDays);
    final endPeriodDay = startCreated.add(Duration(days: durationDays));

    return !startTarget.isAfter(endPeriodDay);
  }

  /// Determines if a habit is scheduled for today
  bool _shouldShowToday(HabitModel habit, DateTime today) {
    if (!_isDateWithinPeriod(habit.createdAt, habit.period, habit.customPeriodDays, today)) {
      return false;
    }

    final habitType = habit.habitType.toLowerCase();

    if (habitType.contains('weekly')) {
      bool completedAnotherDay = habit.completedDates.any((dateKey) {
        final date = _parseDateKey(dateKey);
        return date != null && _isSameWeek(date, today) && !_isSameDay(date, today);
      });
      return !completedAnotherDay;
    }

    if (habitType.contains('monthly')) {
      bool completedAnotherDay = habit.completedDates.any((dateKey) {
        final date = _parseDateKey(dateKey);
        return date != null && _isSameMonth(date, today) && !_isSameDay(date, today);
      });
      return !completedAnotherDay;
    }

    if (habitType.contains('everyday')) return true;
    if (habitType.contains('weekdays')) return today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;
    if (habitType.contains('weekends')) return today.weekday == DateTime.saturday || today.weekday == DateTime.sunday;
    if (habitType.contains('specific days')) {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return habit.specificDays.contains(dayNames[today.weekday - 1]);
    }

    return true;
  }

  /// Calculates progress metrics for goal cards
  Map<String, dynamic> _calculateGoalProgress(HabitModel habit, DateTime today) {
    final totalTargetDays = _getPeriodDurationInDays(habit.period, habit.customPeriodDays);

    // Count completions within current period window
    final completedCount = habit.completedDates.where((dateKey) {
      final date = _parseDateKey(dateKey);
      return date != null && _isDateWithinPeriod(habit.createdAt, habit.period, habit.customPeriodDays, date);
    }).length;

    final double progressRatio = totalTargetDays > 0 ? (completedCount / totalTargetDays).clamp(0.0, 1.0) : 0.0;

    return {
      'progressRatio': progressRatio,
      'progressText': "$completedCount from $totalTargetDays days target",
    };
  }

  /// Refreshes habits data when pulled from top
  Future<void> _handleRefresh(BuildContext context) async {
    await Provider.of<HabitProvider>(context, listen: false).fetchHabits();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final DateTime today = DateTime.now();
    final String todayKey = _formatDateKey(today);

    // Dynamic date string format (e.g. "Sun, 1 Mar 2026")
    final constMonths = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final constWeekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final String formattedDate = "${constWeekdays[today.weekday - 1]}, ${today.day} ${constMonths[today.month - 1]} ${today.year}";

    return Scaffold(
      backgroundColor: AppColors.grey,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          backgroundColor: Colors.white,
          onRefresh: () => _handleRefresh(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Date & Sign Out
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.nunito(
                        color: AppColors.blackGrey,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        authProvider.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) =>  AuthScreen()),
                        );
                      },
                      icon: const Icon(Icons.logout_outlined),
                      color: AppColors.orange,
                    )
                  ],
                ),

                // Greeting Header
                Row(
                  children: [
                    Text(
                      "Hello, ",
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackGrey,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (Rect bounds) => AppColors.orangeGradient.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        "Susy!",
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Dynamic Progress Banner Card
                Consumer<HabitProvider>(
                  builder: (context, habitProvider, child) {
                    final todayHabits = habitProvider.habits.where((h) => _shouldShowToday(h, today)).toList();
                    final completedTodayCount = todayHabits.where((h) => h.completedDates.contains(todayKey)).length;
                    final double overallProgress = todayHabits.isNotEmpty ? (completedTodayCount / todayHabits.length) : 0.0;
                    final int percentage = (overallProgress * 100).round();

                    return Container(
                      width: double.infinity,
                      height: 217,
                      padding: const EdgeInsets.symmetric(horizontal: 41, vertical: 24),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/banner_bg.png'),
                          fit: BoxFit.fill,
                          alignment: Alignment.center,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 117,
                            height: 117,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: overallProgress,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "$percentage%",
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$completedTodayCount of ${todayHabits.length} habits",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "completed today!",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // TODAY HABITS SECTION
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today Habit",
                            style: GoogleFonts.nunito(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackGrey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const YourHabitScreen()),
                              );
                            },
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) => AppColors.orangeGradient.createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                "See all",
                                style: GoogleFonts.nunito(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Consumer<HabitProvider>(
                        builder: (context, habitProvider, child) {
                          if (habitProvider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.orange),
                              ),
                            );
                          }

                          final todayHabits = habitProvider.habits
                              .where((habit) => _shouldShowToday(habit, today))
                              .toList();

                          if (todayHabits.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  "No habits scheduled for today.",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: todayHabits.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final habit = todayHabits[index];
                              final bool isCompleted = habit.completedDates.contains(todayKey);

                              return _buildHabitCard(
                                title: habit.habitName.isNotEmpty ? habit.habitName : habit.goal,
                                isCompleted: isCompleted,
                                onToggle: () {
                                  if (habit.id != null) {
                                    habitProvider.toggleHabitCompletionForDate(
                                      habit.id!,
                                      todayKey,
                                      !isCompleted,
                                    );
                                  }
                                },
                                onEdit: () {
                                  // Edit Habit action
                                },
                                onDelete: () {
                                  if (habit.id != null) {
                                    showDeleteConfirmationDialog(
                                      context: context,
                                      onDeleteConfirm: () => habitProvider.deleteHabit(habit.id!),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // YOUR GOALS SECTION (DISPLAY MAX 3 GOALS)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Your Goals",
                            style: GoogleFonts.nunito(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackGrey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Provider.of<HabitProvider>(context, listen: false).fetchGoals();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const YourGoalsScreen()),
                              );
                            },
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) => AppColors.orangeGradient.createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                "See all",
                                style: GoogleFonts.nunito(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Consumer<HabitProvider>(
                        builder: (context, habitProvider, child) {
                          if (habitProvider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.orange),
                              ),
                            );
                          }

                          // Take maximum 3 goals to show on the dashboard
                          final displayedGoals = habitProvider.habits.take(3).toList();

                          if (displayedGoals.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  "No active goals found.",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: displayedGoals.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final habitGoal = displayedGoals[index];
                              final progressMetrics = _calculateGoalProgress(habitGoal, today);

                              return _buildGoalCard(
                                title: habitGoal.goal.isNotEmpty ? habitGoal.goal : habitGoal.habitName,
                                progressValue: progressMetrics['progressRatio'] as double,
                                progressText: progressMetrics['progressText'] as String,
                                frequency: habitGoal.habitType,
                                onEdit: () {
                                  // Edit Goal action
                                },
                                onDelete: () {
                                  if (habitGoal.id != null) {
                                    showDeleteConfirmationDialog(
                                      context: context,
                                      onDeleteConfirm: () => habitProvider.deleteGoal(habitGoal.id!),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.greenGradient,
          border: Border.all(
            color: AppColors.grey,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF37C871).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => showCreateHabitDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 38),
        ),
      ),
    );
  }

  Widget _buildHabitCard({
    required String title,
    required bool isCompleted,
    required VoidCallback onToggle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFEDFFF4) : AppColors.grey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.transparent : const Color(0xFFEDFFF4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCompleted ? const Color(0xFF37C871) : AppColors.blackGrey,
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: isCompleted ? AppColors.greenGradient : null,
                    color: isCompleted ? null : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted ? Colors.transparent : AppColors.blackGrey,
                      width: 2,
                    ),
                    boxShadow: isCompleted
                        ? [
                      BoxShadow(
                        color: const Color(0xFF37C871).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : [],
                  ),
                  child: isCompleted
                      ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.blackGrey),
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (String value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(
                      'Edit',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blackGrey,
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required double progressValue,
    required String progressText,
    required String frequency,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackGrey,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.blackGrey),
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (String value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(
                      'Edit',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blackGrey,
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth;
                return Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: maxWidth * progressValue,
                    height: 13,
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progressText,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.blackGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            frequency,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}