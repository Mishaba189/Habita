import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habita/screens/success_page.dart';
import '../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import 'delete_confirmation_dialog.dart';


void showCreateHabitDialog(
    BuildContext context, {
      bool isEdit = false,
      HabitModel? goal, // Pass existing goal object when editing
    }) {
  final TextEditingController goalController = TextEditingController(
    text: isEdit && goal != null ? goal.goal : '',
  );
  final TextEditingController habitNameController = TextEditingController(
    text: isEdit && goal != null ? goal.habitName : '',
  );
  final TextEditingController customPeriodController = TextEditingController(
    text: isEdit && goal != null ? goal.customPeriodDays : '',
  );

  final List<String> periodOptions = [
    '1 Week (7 Days)',
    '2 Weeks (14 Days)',
    '1 Month (30 Days)',
    '3 Months (90 Days)',
    '6 Months (180 Days)',
    'Custom',
  ];

  final List<String> habitTypeOptions = [
    'Everyday',
    'Weekdays (Mon-Fri)',
    'Weekends Only',
    'Specific Days',
    'Weekly',
    'Monthly',
  ];

  final List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String selectedPeriod = (isEdit && goal != null && goal.period.isNotEmpty)
      ? goal.period
      : '1 Month (30 Days)';
  String selectedHabitType = (isEdit && goal != null && goal.habitType.isNotEmpty)
      ? goal.habitType
      : 'Everyday';
  final Set<String> selectedSpecificDays = (isEdit && goal != null)
      ? Set<String>.from(goal.specificDays)
      : {'Mon', 'Wed', 'Fri'};

  String? errorMessage;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final habitProvider = Provider.of<HabitProvider>(context);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? "Edit Habit Goal" : "Create New Habit Goal",
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackGrey,
                          ),
                        ),
                        InkWell(
                          onTap: habitProvider.isLoading
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.blackGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Your Goal Field
                    Text(
                      "Your Goal",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blackGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: goalController,
                      style: GoogleFonts.nunito(fontSize: 14),
                      onChanged: (_) {
                        if (errorMessage != null) setState(() => errorMessage = null);
                      },
                      decoration: InputDecoration(
                        hintText: "e.g., Finish 5 Philosophy Books",
                        hintStyle: GoogleFonts.nunito(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFEDEDED)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.orange,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Habit Name Field
                    Text(
                      "Habit Name",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blackGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: habitNameController,
                      style: GoogleFonts.nunito(fontSize: 14),
                      onChanged: (_) {
                        if (errorMessage != null) setState(() => errorMessage = null);
                      },
                      decoration: InputDecoration(
                        hintText: "e.g., Read 15 pages",
                        hintStyle: GoogleFonts.nunito(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFEDEDED)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.orange,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Period Selection Chips/List
                    Text(
                      "Period",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blackGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: periodOptions.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final period = periodOptions[index];
                          final isSelected = selectedPeriod == period;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPeriod = period;
                                if (errorMessage != null) errorMessage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.yellow : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.orange
                                      : const Color(0xFFDEDEDE),
                                ),
                              ),
                              child: Text(
                                period,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.orange
                                      : AppColors.blackGrey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Conditional Custom Period Field
                    if (selectedPeriod == 'Custom') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customPeriodController,
                        style: GoogleFonts.nunito(fontSize: 14),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (errorMessage != null) setState(() => errorMessage = null);
                        },
                        decoration: InputDecoration(
                          hintText: "e.g. 45",
                          hintStyle: GoogleFonts.nunito(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          suffixText: "Days",
                          suffixStyle: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackGrey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEDEDED)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.orange,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Habit Type Selection Chips
                    Text(
                      "Habit Type",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blackGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: habitTypeOptions.map((type) {
                        final isSelected = selectedHabitType == type;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedHabitType = type;
                              if (errorMessage != null) errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.yellow : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.orange
                                    : const Color(0xFFDEDEDE),
                              ),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.orange
                                    : AppColors.blackGrey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Conditional Specific Days Multi-Select
                    if (selectedHabitType == 'Specific Days') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEDEDED)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Days",
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: daysOfWeek.map((day) {
                                final isDaySelected =
                                selectedSpecificDays.contains(day);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isDaySelected) {
                                        selectedSpecificDays.remove(day);
                                      } else {
                                        selectedSpecificDays.add(day);
                                      }
                                      if (errorMessage != null) {
                                        errorMessage = null;
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDaySelected
                                          ? AppColors.yellow
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDaySelected
                                            ? AppColors.orange
                                            : const Color(0xFFDEDEDE),
                                      ),
                                    ),
                                    child: Text(
                                      day[0],
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDaySelected
                                            ? AppColors.orange
                                            : AppColors.blackGrey,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Inline Error Banner
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFC1C1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: Color(0xFFE53935),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Primary Action Button (Create / Update)
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: habitProvider.isLoading
                            ? null
                            : () async {
                          final textGoal = goalController.text.trim();
                          final habitName = habitNameController.text.trim();
                          final customDays =
                          customPeriodController.text.trim();

                          if (textGoal.isEmpty || habitName.isEmpty) {
                            setState(() {
                              errorMessage =
                              "Please fill in both goal and habit fields.";
                            });
                            return;
                          }

                          if (selectedPeriod == 'Custom' &&
                              customDays.isEmpty) {
                            setState(() {
                              errorMessage =
                              "Please specify custom period days.";
                            });
                            return;
                          }

                          if (selectedHabitType == 'Specific Days' &&
                              selectedSpecificDays.isEmpty) {
                            setState(() {
                              errorMessage = "Please select at least one day.";
                            });
                            Icon: return;
                          }

                          setState(() {
                            errorMessage = null;
                          });

                          if (isEdit) {
                            if (goal?.id == null) return;
                            // Call update function in Provider
                            final success = await habitProvider.updateHabit(
                              habitId: goal!.id!,
                              goal: textGoal,
                              habitName: habitName,
                              period: selectedPeriod,
                              customPeriodDays: customDays,
                              habitType: selectedHabitType,
                              specificDays: selectedSpecificDays,
                            );

                            if (success && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              Navigator.push(
                                dialogContext,
                                MaterialPageRoute(
                                  builder: (_) => const HabitSuccessScreen(
                                    title: "Updated!",
                                    message: "Habit goal updated successfully.\nKeep up the progress!",
                                  ),
                                ),
                              );
                            } else if (dialogContext.mounted) {
                              setState(() {
                                errorMessage =
                                "Failed to update habit. Please try again.";
                              });
                            }
                          } else {
                            // Call create function in Provider
                            final success = await habitProvider.createHabit(
                              goal: textGoal,
                              habitName: habitName,
                              period: selectedPeriod,
                              customPeriodDays: customDays,
                              habitType: selectedHabitType,
                              specificDays: selectedSpecificDays,
                            );

                            if (success && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              Navigator.push(
                                dialogContext,
                                MaterialPageRoute(
                                  builder: (_) => const HabitSuccessScreen(),
                                ),
                              );
                            } else if (dialogContext.mounted) {
                              setState(() {
                                errorMessage =
                                "Failed to create habit. Please try again.";
                              });
                            }
                          }
                        },
                        child: habitProvider.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          isEdit ? "Save Changes" : "Create New",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Extra Delete Button (Appears only when isEdit is true)
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFCDD2)),
                            backgroundColor: const Color(0xFFFFF5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          label: Text(
                            "Delete Goal",
                            style: GoogleFonts.nunito(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: habitProvider.isLoading
                              ? null
                              : () {
                            if (goal?.id == null) return;
                            Navigator.pop(dialogContext);
                            showDeleteConfirmationDialog(
                              context: context,
                              onDeleteConfirm: () {
                                habitProvider.deleteGoal(goal!.id!);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
