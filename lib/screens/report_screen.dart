import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habita/screens/your_goals_report_screen.dart';
import 'package:habita/screens/your_goal_screen.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/habit_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/calender.dart';
import '../widgets/empty_state.dart';
import 'goal_detail_screen.dart';

class HabitItem {
  final String progressPercentage;
  final String title;
  final String subtitle;
  final bool isAchieved;

  const HabitItem({
    required this.progressPercentage,
    required this.title,
    required this.subtitle,
    required this.isAchieved,
  });
}


class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});

  final ValueNotifier<String> _selectedDateRangeText =
  ValueNotifier<String>('This Month');
  final ValueNotifier<DateTime> _focusedDay =
  ValueNotifier<DateTime>(DateTime.now());
  final ValueNotifier<DateTime?> _selectedDay =
  ValueNotifier<DateTime?>(null);
  final ValueNotifier<DateTime?> _rangeStart =
  ValueNotifier<DateTime?>(null);
  final ValueNotifier<DateTime?> _rangeEnd =
  ValueNotifier<DateTime?>(null);

  void _showCalendarDialog(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    showCalendarDialog(
      context: context,
      initialFocusedDay: _focusedDay.value,
      initialSelectedDay: _selectedDay.value,
      initialRangeStart: _rangeStart.value,
      initialRangeEnd: _rangeEnd.value,
      onClearFilter: () {
        _selectedDay.value = null;
        _rangeStart.value = null;
        _rangeEnd.value = null;
        _selectedDateRangeText.value = 'This Month';

        reportProvider.clearFilter();
        Navigator.pop(context);
      },
      onApply: (focused, selected, start, end) {
        _focusedDay.value = focused;
        _selectedDay.value = selected;
        _rangeStart.value = start;
        _rangeEnd.value = end;

        // Pass selection to provider so all calculations re-trigger
        reportProvider.setDateFilter(
          selectedDay: selected,
          start: start,
          end: end,
        );

        final List<String> monthAbbrs = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];

        String formatDate(DateTime date) =>
            "${date.day} ${monthAbbrs[date.month - 1]} ${date.year}";

        if (start != null && end != null) {
          _selectedDateRangeText.value =
          "${formatDate(start)} - ${formatDate(end)}";
        } else if (start != null) {
          _selectedDateRangeText.value = formatDate(start);
        } else if (selected != null) {
          _selectedDateRangeText.value = formatDate(selected);
        } else {
          _selectedDateRangeText.value = 'This Month';
        }
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Consumer2<HabitProvider, ReportProvider>(
          builder: (context, habitProvider, reportProvider, child) {
            final allHabits = habitProvider.habits;

            // Filter habits active within the selected date range
            final activeHabits = reportProvider.getActiveHabitsInRange(allHabits);

            final overallProgress =
            reportProvider.calculateProgressPercentage(
              activeHabits,
              habitProvider,
            );
            final achievedCount =
            reportProvider.getAchievedCount(
              activeHabits,
              habitProvider,
            );
            final unachievedCount =
            reportProvider.getUnachievedCount(
              activeHabits,
              habitProvider,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Title
                  Text(
                    'Progress',
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackGrey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Report Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress Report',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blackGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showCalendarDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEFEF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              ValueListenableBuilder<String>(
                                valueListenable: _selectedDateRangeText,
                                builder: (context, selectedText, child) {
                                  return Text(
                                    selectedText,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.blackGrey,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.blackGrey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dynamic UI: Loading, Empty State, or Progress Card
                  if (activeHabits.isEmpty)
                    buildEmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: 'No Active Goals',
                      subtitle:
                      'There are no active habits or goals found for the selected date range.',
                      buttonText: 'Reset Filter',
                      onButtonPressed: () {
                        _selectedDay.value = null;
                        _rangeStart.value = null;
                        _rangeEnd.value = null;
                        _selectedDateRangeText.value = 'This Month';
                        reportProvider.clearFilter();
                      },
                    )
                  else
                  // Main Progress Card Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Card Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Goals',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blackGrey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => YourGoalsScreen()),
                                  );
                                },
                                child: Text(
                                  'See all',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Donut Progress Indicator
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(190, 190),
                                  painter: _DonutChartPainter(
                                    progress: overallProgress / 100.0,
                                  ),
                                ),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) {
                                    return AppColors.orangeGradient
                                        .createShader(bounds);
                                  },
                                  child: Text(
                                    '$overallProgress%',
                                    style: GoogleFonts.nunito(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 13),

                          // Goal Status Summaries
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (Rect bounds) {
                              return AppColors.orangeGradient
                                  .createShader(bounds);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '$achievedCount Habits goal has achieved',
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                "$unachievedCount Habits goal hasn't achieved",
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Active Habit List Items
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: math.min(3, activeHabits.length),
                            separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final habit = activeHabits[index];

                              final List<dynamic> safeCompletedDates =
                                  (habit.completedDates as List?) ?? [];

                              final int targetDays =
                              habitProvider.calculateTargetDays(habit);

                              final int completedDays =
                              reportProvider.getCompletedDaysForRange(
                                safeCompletedDates,
                              );

                              final double ratio = targetDays > 0
                                  ? (completedDays / targetDays).clamp(0.0, 1.0)
                                  : 0.0;

                              final int percentage = (ratio * 100).round();

                              final bool isAchieved =
                                  targetDays > 0 && completedDays >= targetDays;

                              final String titleText = habit.goal.isNotEmpty
                                  ? habit.goal
                                  : habit.habitName;

                              final String subtitleText =
                                  "$completedDays from $targetDays days target";
                              return GestureDetector(
                                onTap: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GoalDetailsScreen(habit: habit),
                                    ),
                                  );
                                },
                                child: _buildHabitTile(
                                  progressPercentage: '$percentage%',
                                  title: titleText,
                                  subtitle: subtitleText,
                                  isAchieved: isAchieved,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Bottom Link
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => YourGoalsReportScreen()),
                              );
                            },
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) => AppColors
                                  .orangeGradient
                                  .createShader(bounds),
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
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildHabitTile({
    required String progressPercentage,
    required String title,
    required String subtitle,
    required bool isAchieved,
  }) {
    final double percentageValue =
        double.tryParse(progressPercentage.replaceAll('%', '')) ?? 0.0;
    final double progressRatio = (percentageValue / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Circular progress ring indicator
          SizedBox(
            width: 49,
            height: 49,
            child: CustomPaint(
              painter: RingProgressPainter(
                progress: progressRatio,
                isAchieved: isAchieved,
              ),
              child: Center(
                child: isAchieved
                    ? ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      AppColors.greenGradient.createShader(bounds),
                  child: Text(
                    progressPercentage,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
                    : Text(
                  progressPercentage,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Right Status Badge
          if (isAchieved)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F8EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Achieved',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            )
          else
            Text(
              'Unachieved',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGrey,
              ),
            ),
        ],
      ),
    );
  }
}


// Custom Painter for main Donut Chart
class _DonutChartPainter extends CustomPainter {
  final double progress;

  _DonutChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 22.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Background track
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      bgPaint,
    );

    // Foreground progress arc with gradient
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint progressPaint = Paint()
      ..shader = AppColors.orangeGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start angle: -pi / 2 (top), sweep angle based on progress
    const double startAngle = -pi / 2;
    final double sweepAngle = 2 * pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RingProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool isAchieved;

  RingProgressPainter({
    required this.progress,
    required this.isAchieved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.5;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Background Track (Light Grey)
    final Paint trackPaint = Paint()
      ..color = AppColors.lightGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc
    if (progress > 0) {
      final Paint progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isAchieved) {
        progressPaint.shader = AppColors.greenGradient.createShader(rect);
      } else {
        progressPaint.color = AppColors.darkGrey;
      }

      // Draw starting from top (-90 degrees)
      const double startAngle = -3.141592653589793 / 2;
      final double sweepAngle = 2 * 3.141592653589793 * progress;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isAchieved != isAchieved;
  }
}