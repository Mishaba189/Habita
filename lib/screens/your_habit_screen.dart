import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class HabitItem {
  String title;
  bool isCompleted;

  HabitItem({required this.title, required this.isCompleted});
}

class YourHabitScreen extends StatelessWidget {
  final ValueNotifier<List<HabitItem>> habitsNotifier;
  final ValueNotifier<DateTime> selectedDateNotifier;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<int>? onHabitToggled;
  final Function(int index)? onEdit;
  final Function(int index)? onDelete;

  YourHabitScreen({
    super.key,
    List<HabitItem>? habits,
    DateTime? initialSelectedDate,
    this.onDateSelected,
    this.onHabitToggled,
    this.onEdit,
    this.onDelete,
  })  : habitsNotifier = ValueNotifier(
    habits ??
        [
          HabitItem(title: "Meditating", isCompleted: true),
          HabitItem(title: "Read Philosophy", isCompleted: true),
          HabitItem(title: "Journaling", isCompleted: false),
        ],
  ),
        selectedDateNotifier = ValueNotifier(initialSelectedDate ?? DateTime.now());

  // Generates 15 days before today + today + 30 days after today (46 days total)
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

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final List<DateTime> dateList = _generateDays(today);

    // Index 15 corresponds to 'Today'
    final ScrollController calendarScrollController = ScrollController(
      initialScrollOffset: 15 * 64.0,
    );

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

                // --- 15 DAYS BEFORE / 30 DAYS AFTER CALENDAR SELECTOR ---
                SizedBox(
                  height: 64,
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: selectedDateNotifier,
                    builder: (context, selectedDate, child) {
                      return ListView.separated(
                        controller: calendarScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: dateList.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final dayDate = dateList[index];
                          final isSelected = dayDate.year == selectedDate.year &&
                              dayDate.month == selectedDate.month &&
                              dayDate.day == selectedDate.day;

                          return GestureDetector(
                            onTap: () {
                              selectedDateNotifier.value = dayDate;
                              onDateSelected?.call(dayDate);
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // --- MAIN HABITS CONTAINER CARD ---
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
                        "Today Habit",
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackGrey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List of Habit Items using ValueListenableBuilder
                      ValueListenableBuilder<List<HabitItem>>(
                        valueListenable: habitsNotifier,
                        builder: (context, habits, child) {
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: habits.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final habit = habits[index];
                              return _buildHabitCard(
                                habit: habit,
                                onToggle: () {
                                  habit.isCompleted = !habit.isCompleted;
                                  habitsNotifier.value = List.from(habits);
                                  onHabitToggled?.call(index);
                                },
                                onEdit: () => onEdit?.call(index),
                                onDelete: () => onDelete?.call(index),
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
    required HabitItem habit,
    required VoidCallback onToggle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: habit.isCompleted ? const Color(0xFFEDFFF4) : AppColors.grey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: habit.isCompleted ? Colors.transparent : const Color(0xFFEDFFF4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.title,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: habit.isCompleted ? const Color(0xFF37C871) : AppColors.blackGrey,
              ),
            ),
          ),

          // Custom Green Checkbox with Tap Target
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: habit.isCompleted ? AppColors.greenGradient : null,
                color: habit.isCompleted ? null : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: habit.isCompleted ? Colors.transparent : AppColors.blackGrey,
                  width: 2,
                ),
                boxShadow: habit.isCompleted
                    ? [
                  BoxShadow(
                    color: const Color(0xFF37C871).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : [],
              ),
              child: habit.isCompleted
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
                    color: AppColors.blackGrey,
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