import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/habit_model.dart';

class GoalDetailsScreen extends StatelessWidget {
  final HabitModel habit;

  const GoalDetailsScreen({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Start Date, Target Days, End Date, & Today
    final DateTime startDate = habit.createdAt;
    final int targetDays = _getCalculatedTargetDays();

    // Corrected End Date: Add (targetDays - 1) days so a 5-day goal encompasses exactly 5 calendar days.
    final DateTime endDate = targetDays > 0
        ? startDate.add(Duration(days: targetDays - 1))
        : startDate;

    final DateTime today = DateTime.now();

    // 2. Parse Safe Completed Dates
    final List<DateTime> safeCompletedDates = (habit.completedDates as List?)
        ?.map((e) => e is DateTime ? e : DateTime.tryParse(e.toString()))
        .whereType<DateTime>()
        .toList() ??
        <DateTime>[];

    // 3. Calculate Stats
    final int completedDays = safeCompletedDates.where((d) {
      final dateOnly = DateTime(d.year, d.month, d.day);
      final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
      final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
      return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
    }).length;

    final bool isAchieved = targetDays > 0 && completedDays >= targetDays;

    // Calculate failed days up to today (or goal end date, whichever comes first)
    int failedDays = 0;
    DateTime tempDate = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    final DateTime endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    while (!tempDate.isAfter(todayOnly) && !tempDate.isAfter(endOnly)) {
      final bool isDone = safeCompletedDates.any((d) =>
      d.year == tempDate.year &&
          d.month == tempDate.month &&
          d.day == tempDate.day);
      if (!isDone) {
        failedDays++;
      }
      tempDate = tempDate.add(const Duration(days: 1));
    }

    final String displayTitle = habit.goal.isNotEmpty ? habit.goal : habit.habitName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Goal: $displayTitle',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B2B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              _buildCalendarCard(
                startDate: startDate,
                endDate: endDate,
                today: today,
                completedDates: safeCompletedDates,
              ),
              const SizedBox(height: 16),
              _buildHabitDetailsCard(
                displayTitle: displayTitle,
                habitName: habit.habitName,
                targetDays: targetDays,
                completedDays: completedDays,
                failedDays: failedDays,
                habitType: habit.habitType.isNotEmpty ? habit.habitType : (habit.period ?? ''),
                createdAt: startDate,
                isAchieved: isAchieved,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCalculatedTargetDays() {
    if (habit.period == 'Custom') {
      if (habit.customPeriodDays is int) {
        return habit.customPeriodDays as int;
      }
      return int.tryParse(habit.customPeriodDays?.toString() ?? '') ?? 0;
    }
    switch (habit.period?.toLowerCase()) {
      case 'daily':
      case 'everyday':
        return 30;
      case 'weekly':
        return 7;
      case 'monthly':
        return 30;
      default:
        return 30;
    }
  }

  Widget _buildCalendarCard({
    required DateTime startDate,
    required DateTime endDate,
    required DateTime today,
    required List<DateTime> completedDates,
  }) {
    final DateTime startMonth = DateTime(startDate.year, startDate.month, 1);
    final DateTime endMonth = DateTime(endDate.year, endDate.month, 1);
    final DateTime currentMonth = DateTime(today.year, today.month, 1);

    DateTime tempFocusedDay = (currentMonth.isAfter(endMonth) || currentMonth.isBefore(startMonth))
        ? startMonth
        : currentMonth;
    DateTime? tempSelectedDay = today;

    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    String formatDate(DateTime date) {
      return "${monthNames[date.month - 1]} ${date.day}, ${date.year}";
    }

    bool isSameDay(DateTime? a, DateTime? b) {
      if (a == null || b == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    bool isDateOnlyBefore(DateTime a, DateTime b) {
      return DateTime(a.year, a.month, a.day)
          .isBefore(DateTime(b.year, b.month, b.day));
    }

    bool isDateOnlyAfter(DateTime a, DateTime b) {
      return DateTime(a.year, a.month, a.day)
          .isAfter(DateTime(b.year, b.month, b.day));
    }

    return StatefulBuilder(
      builder: (context, setCardState) {
        bool canGoPrevious = tempFocusedDay.isAfter(startMonth);
        bool canGoNext = tempFocusedDay.isBefore(endMonth);

        void previousMonth() {
          if (canGoPrevious) {
            setCardState(() {
              tempFocusedDay = DateTime(
                tempFocusedDay.year,
                tempFocusedDay.month - 1,
                1,
              );
            });
          }
        }

        void nextMonth() {
          if (canGoNext) {
            setCardState(() {
              tempFocusedDay = DateTime(
                tempFocusedDay.year,
                tempFocusedDay.month + 1,
                1,
              );
            });
          }
        }

        final year = tempFocusedDay.year;
        final month = tempFocusedDay.month;
        final firstDayOfMonth = DateTime(year, month, 1);
        final daysInMonth = DateTime(year, month + 1, 0).day;

        final int leadingEmptyDays = firstDayOfMonth.weekday - 1;
        final previousMonthLastDay = DateTime(year, month, 0).day;
        final List<DateTime> gridDates = [];

        for (int i = leadingEmptyDays - 1; i >= 0; i--) {
          gridDates.add(DateTime(year, month - 1, previousMonthLastDay - i));
        }
        for (int i = 1; i <= daysInMonth; i++) {
          gridDates.add(DateTime(year, month, i));
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start date',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDate(startDate),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B2B2B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: canGoPrevious
                              ? Colors.grey[800]
                              : Colors.grey[300],
                        ),
                        onPressed: canGoPrevious ? previousMonth : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        monthNames[tempFocusedDay.month - 1],
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF5216),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: canGoNext
                              ? Colors.grey[800]
                              : Colors.grey[300],
                        ),
                        onPressed: canGoNext ? nextMonth : null,
                      ),
                    ],
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'End date',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDate(endDate),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B2B2B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                    .map(
                      (day) => SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.1,
                ),
                itemCount: gridDates.length,
                itemBuilder: (context, index) {
                  final date = gridDates[index];
                  final isSelectedDay = isSameDay(date, tempSelectedDay);

                  final bool isWithinRange =
                      !isDateOnlyBefore(date, startDate) &&
                          !isDateOnlyAfter(date, endDate);

                  final bool isCompleted = completedDates.any(
                        (completedDate) => isSameDay(completedDate, date),
                  );

                  final bool isPastOrToday = !isDateOnlyAfter(date, today);
                  final bool isFailed =
                      isWithinRange && isPastOrToday && !isCompleted;
                  final bool isUpcoming =
                      isWithinRange && isDateOnlyAfter(date, today);

                  final bool isFirstInRow = index % 7 == 0;
                  final bool isLastInRow = index % 7 == 6;

                  BorderRadius pillRadius = BorderRadius.horizontal(
                    left: isFirstInRow ? const Radius.circular(6) : Radius.zero,
                    right: isLastInRow ? const Radius.circular(6) : Radius.zero,
                  );

                  return GestureDetector(
                    onTap: () {
                      setCardState(() {
                        tempSelectedDay = date;
                      });
                    },
                    child: Center(
                      child: isSelectedDay
                          ? Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B2B2B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : isWithinRange && isCompleted
                          ? Container(
                        height: 26,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0F8E2),
                          borderRadius: pillRadius,
                        ),
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2B2B2B),
                          ),
                        ),
                      )
                          : isFailed
                          ? Container(
                        height: 26,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDADA),
                          borderRadius: pillRadius,
                        ),
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD32F2F),
                          ),
                        ),
                      )
                          : isUpcoming
                          ? Container(
                        height: 26,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: pillRadius,
                        ),
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      )
                          : Container(
                        alignment: Alignment.center,
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: date.month == month
                                ? const Color(0xFF2B2B2B)
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitDetailsCard({
    required String displayTitle,
    required String habitName,
    required int targetDays,
    required int completedDays,
    required int failedDays,
    required String habitType,
    required DateTime createdAt,
    required bool isAchieved,
  }) {
    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final String formattedCreatedDate =
        "${monthNames[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Expanded(
                child: Text(
                  displayTitle,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2B2B2B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAchieved)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0F8E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Achieved',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Habit Name:', habitName),
          _buildDetailRow('Target:', '$targetDays Days'),
          _buildDetailRow('Days complete:', '$completedDays Days'),
          _buildDetailRow('Days failed:', '$failedDays Days'),
          _buildDetailRow('Habit type', habitType),
          _buildDetailRow('Created on', formattedCreatedDate, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2B2B2B),
            ),
          ),
        ],
      ),
    );
  }
}

