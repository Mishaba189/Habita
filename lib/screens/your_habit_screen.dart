import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/create_habit_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_state.dart';


class YourHabitScreen extends StatefulWidget {
  final DateTime? initialSelectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final Function(String habitId)? onEdit;

  const YourHabitScreen({
    super.key,
    this.initialSelectedDate,
    this.onDateSelected,
    this.onEdit,
  });

  @override
  State<YourHabitScreen> createState() => _YourHabitScreenState();
}

class _YourHabitScreenState extends State<YourHabitScreen> {
  late DateTime _selectedDate;
  late ScrollController _calendarScrollController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialSelectedDate ?? DateTime(now.year, now.month, now.day);
    _calendarScrollController = ScrollController(
      initialScrollOffset: 15 * 64.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HabitProvider>(context, listen: false).fetchHabits();
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  /// Format date to yyyy-MM-dd key string
  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  List<DateTime> _generateDays(DateTime baseDate) {
    final today = DateTime(baseDate.year, baseDate.month, baseDate.day);
    return List.generate(
      46,
          (index) => today.add(Duration(days: index - 15)),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

  bool _isDateWithinPeriod(DateTime createdAt, String period, String? customPeriodDays, DateTime selectedDate) {
    final startOfDayCreated = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final startOfSelectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (startOfSelectedDay.isBefore(startOfDayCreated)) return false;

    final durationDays = _getPeriodDurationInDays(period, customPeriodDays);
    final endOfPeriodDay = startOfDayCreated.add(Duration(days: durationDays));

    if (startOfSelectedDay.isAfter(endOfPeriodDay)) return false;

    return true;
  }


  /// Checks if two dates fall into the same ISO calendar week (Mon-Sun)
  bool _isSameWeek(DateTime d1, DateTime d2) {
    // Adjust to start of the week (Monday)
    final startOfWeek1 = d1.subtract(Duration(days: d1.weekday - 1));
    final startOfWeek2 = d2.subtract(Duration(days: d2.weekday - 1));

    return startOfWeek1.year == startOfWeek2.year &&
        startOfWeek1.month == startOfWeek2.month &&
        startOfWeek1.day == startOfWeek2.day;
  }

  /// Checks if two dates fall into the same calendar month
  bool _isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }

  /// Parses yyyy-MM-dd strings back to DateTime objects
  DateTime? _parseDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return null;
  }

  bool _shouldShowOnDay(HabitModel habit, DateTime selectedDate) {
    // 1. Ensure the selected date is inside the overall habit duration
    if (!_isDateWithinPeriod(habit.createdAt, habit.period, habit.customPeriodDays, selectedDate)) {
      return false;
    }

    final weekday = selectedDate.weekday;
    final habitType = habit.habitType.toLowerCase();

    // 2. Handle Weekly Frequency Logic
    if (habitType.contains('weekly')) {
      // Check if it was completed on a DIFFERENT day in the same week
      bool completedOnAnotherDayThisWeek = habit.completedDates.any((dateKey) {
        final completedDate = _parseDateKey(dateKey);
        if (completedDate == null) return false;

        // Matches same week BUT is not the currently viewed date
        return _isSameWeek(completedDate, selectedDate) && !_isSameDay(completedDate, selectedDate);
      });

      // Hide only if completed on another day of the week
      if (completedOnAnotherDayThisWeek) return false;
      return true;
    }

    // 3. Handle Monthly Frequency Logic
    if (habitType.contains('monthly')) {
      // Check if it was completed on a DIFFERENT day in the same month
      bool completedOnAnotherDayThisMonth = habit.completedDates.any((dateKey) {
        final completedDate = _parseDateKey(dateKey);
        if (completedDate == null) return false;

        // Matches same month BUT is not the currently viewed date
        return _isSameMonth(completedDate, selectedDate) && !_isSameDay(completedDate, selectedDate);
      });

      // Hide only if completed on another day of the month
      if (completedOnAnotherDayThisMonth) return false;
      return true;
    }

    // 4. Handle Standard Recurrence Types
    if (habitType.contains('everyday')) {
      return true;
    } else if (habitType.contains('weekdays')) {
      return weekday >= DateTime.monday && weekday <= DateTime.friday;
    } else if (habitType.contains('weekends')) {
      return weekday == DateTime.saturday || weekday == DateTime.sunday;
    } else if (habitType.contains('specific days')) {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final selectedDayName = dayNames[weekday - 1];
      return habit.specificDays.contains(selectedDayName);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final List<DateTime> dateList = _generateDays(today);
    final String selectedDateKey = _formatDateKey(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.grey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ROW ---
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.blackGrey,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Your Habit",
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- CALENDAR STRIP ---
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    controller: _calendarScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: dateList.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final dayDate = dateList[index];
                      final isSelected = _isSameDay(dayDate, _selectedDate);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
                          });
                          widget.onDateSelected?.call(dayDate);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF0E6) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.yellow : const Color(0xFFEBEBEB),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${dayDate.day}",
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.orange : AppColors.blackGrey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getMonthAbbreviation(dayDate.month),
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.orange : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // --- MAIN HABITS CARD ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSameDay(_selectedDate, DateTime.now())
                            ? "Today Habit"
                            : "Habits for ${_selectedDate.day} ${_getMonthAbbreviation(_selectedDate.month)}",
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackGrey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Consumer<HabitProvider>(
                        builder: (context, habitProvider, child) {
                          // if (habitProvider.isLoading) {
                          //   return const Center(
                          //     child: Padding(
                          //       padding: EdgeInsets.all(24.0),
                          //       child: CircularProgressIndicator(color: AppColors.orange),
                          //     ),
                          //   );
                          // }

                          final filteredHabits = habitProvider.habits.where((habit) {
                            return _shouldShowOnDay(habit, _selectedDate);
                          }).toList();

                          if (filteredHabits.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: buildEmptyState(
                                  icon: Icons.event_note_rounded,
                                  title: _isSameDay(_selectedDate, DateTime.now())
                                      ? "No Habits Today"
                                      : "No Habits for ${_selectedDate.day} ${_getMonthAbbreviation(_selectedDate.month)}",
                                  subtitle: "No habits scheduled for this date !",
                                  buttonText: "Add New Habit",
                                  onButtonPressed: () =>  showCreateHabitDialog(context),
                                )
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredHabits.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final habit = filteredHabits[index];
                              final bool isCompletedForSelectedDate =
                                  habit.completedDates?.contains(selectedDateKey) ??
                                      (_isSameDay(_selectedDate, DateTime.now()) ? habit.isCompleted : false);
                              return _buildHabitCard(
                                context: context,
                                habit: habit,
                                isCompleted: isCompletedForSelectedDate,
                                onToggle: () {
                                  if (habit.id != null) {
                                    habitProvider.toggleHabitCompletionForDate(
                                      habit.id!,
                                      selectedDateKey,
                                      !isCompletedForSelectedDate,
                                    );
                                  }
                                },
                                onEdit: () {
                                  if (habit.id != null) {
                                    showCreateHabitDialog(
                                      context,
                                      isEdit: true,
                                      goal: habit,
                                    );
                                  }
                                },
                                onDelete: () {
                                  if (habit.id != null) {
                                    showDeleteConfirmationDialog(
                                      context: context,
                                      onDeleteConfirm: () {
                                        habitProvider.deleteHabit(habit.id!);
                                      },
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard({
    required BuildContext context,
    required HabitModel habit,
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
        children: [
          Expanded(
            child: Text(
              habit.habitName.isNotEmpty ? habit.habitName : habit.goal,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCompleted ? const Color(0xFF37C871) : AppColors.blackGrey,
              ),
            ),
          ),

          // Custom Green Checkbox
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

          // Options Menu
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
          ),
        ],
      ),
    );
  }
}