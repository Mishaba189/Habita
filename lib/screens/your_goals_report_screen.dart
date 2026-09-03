import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habita/screens/goal_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:habita/providers/habit_provider.dart';
import 'package:habita/providers/report_provider.dart';

import '../constants/app_colors.dart';
import '../widgets/calender.dart';
import 'report_screen.dart';

enum GoalFilter { all, achieved, unachieved }

class YourGoalsReportScreen extends StatelessWidget {
  YourGoalsReportScreen({super.key});

  final ValueNotifier<GoalFilter> _selectedFilter =
  ValueNotifier<GoalFilter>(GoalFilter.all);

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

  /// Shows calendar picker dialog and updates ReportProvider + UI text label
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Your Goals',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B2B2B),
          ),
        ),
        centerTitle: false,
        actions: [
          // Date Filter Dropdown Badge with ValueListenableBuilder
          GestureDetector(
            onTap: () => _showCalendarDialog(context),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          color: const Color(0xFF2B2B2B),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF2B2B2B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<HabitProvider, ReportProvider>(
          builder: (context, habitProvider, reportProvider, child) {
            final allHabits = habitProvider.habits;
            final activeHabits =
            reportProvider.getActiveHabitsInRange(allHabits);

            return ValueListenableBuilder<GoalFilter>(
              valueListenable: _selectedFilter,
              builder: (context, currentFilter, child) {
                // Filter habits based on current tab selection
                final filteredHabits = activeHabits.where((habit) {
                  final List<DateTime> safeCompletedDates =
                      (habit.completedDates as List?)
                          ?.map((e) => e is DateTime
                          ? e
                          : DateTime.tryParse(e.toString()))
                          .whereType<DateTime>()
                          .toList() ??
                          <DateTime>[];

                  final int targetDays =
                  habitProvider.calculateTargetDays(habit);

                  final int completedDays =
                  reportProvider.getCompletedDaysForRange(
                    safeCompletedDates,
                  );

                  final bool isAchieved =
                      targetDays > 0 && completedDays >= targetDays;

                  switch (currentFilter) {
                    case GoalFilter.achieved:
                      return isAchieved;

                    case GoalFilter.unachieved:
                      return !isAchieved;

                    case GoalFilter.all:
                    default:
                      return true;
                  }
                }).toList();

                return Column(
                  children: [
                    const SizedBox(height: 12),

                    // --- Segment Filter Tabs (All / Achieved / Unachieved) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildFilterTab(
                              label: 'All',
                              filter: GoalFilter.all,
                              currentFilter: currentFilter,
                              count: activeHabits.length,
                            ),
                            _buildFilterTab(
                              label: 'Achieved',
                              filter: GoalFilter.achieved,
                              currentFilter: currentFilter,
                              count: reportProvider.getAchievedCount(
                                activeHabits,
                                habitProvider,
                              ),
                            ),
                            _buildFilterTab(
                              label: 'Unachieved',
                              filter: GoalFilter.unachieved,
                              currentFilter: currentFilter,
                              count: reportProvider.getUnachievedCount(
                                activeHabits,
                                habitProvider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Habits Container Card ---
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 8.0,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: filteredHabits.isEmpty
                              ? _buildEmptyFilterState()
                              : ListView.separated(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: filteredHabits.length,
                            separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final habit = filteredHabits[index];

                              final List<DateTime> safeCompletedDates =
                                  (habit.completedDates as List?)
                                      ?.map((e) => e is DateTime
                                      ? e
                                      : DateTime.tryParse(e.toString()))
                                      .whereType<DateTime>()
                                      .toList() ??
                                      <DateTime>[];

                              final int targetDays =
                              habitProvider.calculateTargetDays(habit);


                              final int completedDays = reportProvider
                                  .getCompletedDaysForRange(
                                safeCompletedDates,
                              );

                              final double ratio = targetDays > 0
                                  ? (completedDays / targetDays)
                                  .clamp(0.0, 1.0)
                                  : 0.0;

                              final int percentage =
                              (ratio * 100).round();
                              final bool isAchieved = targetDays > 0 &&
                                  completedDays >= targetDays;

                              final String titleText =
                              habit.goal.isNotEmpty
                                  ? habit.goal
                                  : habit.habitName;

                              final String subtitleText =
                                  "$completedDays from $targetDays days target";

                              return GestureDetector(
                                onTap: () {
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
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Individual Segment Tab Button
  Widget _buildFilterTab({
    required String label,
    required GoalFilter filter,
    required GoalFilter currentFilter,
    required int count,
  }) {
    final bool isSelected = currentFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectedFilter.value = filter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            '$label ($count)',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF2B2B2B) : Colors.grey[600],
            ),
          ),
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

  /// Empty state when no goals match the filter
  Widget _buildEmptyFilterState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36.0),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No goals found',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'There are no habits matching this status.',
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}