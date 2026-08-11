import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/delete_confirmation_dialog.dart';


class YourGoalsScreen extends StatelessWidget {
  final Function(String goalId)? onEdit;
  final Function(String goalId)? onDelete;

  const YourGoalsScreen({
    super.key,
    this.onEdit,
    this.onDelete,
  });

  /// Helper to get the total target days from period string
  int _getTotalDays(String period, String? customPeriodDays) {
    if (period.contains('7 Days')) return 7;
    if (period.contains('14 Days')) return 14;
    if (period.contains('30 Days') || period.contains('1 Month')) return 30;
    if (period.contains('90 Days') || period.contains('3 Months')) return 90;
    if (period == 'Custom' && customPeriodDays != null) {
      return int.tryParse(customPeriodDays) ?? 30;
    }
    return 30;
  }

  /// Helper to calculate current progress directly from completed dates count
  int _calculateCompletedDaysProgress(List<String> completedDates, int totalDays) {
    return completedDates.length.clamp(0, totalDays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Back button and Title
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
                    "Your Goals",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Goals List Consumer
              Expanded(
                child: Consumer<HabitProvider>(
                  builder: (context, habitProvider, child) {
                    if (habitProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.orange),
                      );
                    }

                    if (habitProvider.goals.isEmpty) {
                      return Center(
                        child: Text(
                          "No goals created yet.",
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: habitProvider.goals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final HabitModel goal = habitProvider.goals[index];

                        final int totalDays = _getTotalDays(goal.period, goal.customPeriodDays);

                        // Updated to use actual toggled completed dates count
                        final int currentProgress = _calculateCompletedDaysProgress(
                          goal.completedDates,
                          totalDays,
                        );

                        final double progressRatio = totalDays > 0
                            ? (currentProgress / totalDays).clamp(0.0, 1.0)
                            : 0.0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title & PopUp Menu Option
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.goal.isNotEmpty ? goal.goal : goal.habitName,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.blackGrey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: AppColors.blackGrey,
                                    ),
                                    color: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    onSelected: (String value) {
                                      if (goal.id == null) return;

                                      if (value == 'edit') {
                                        onEdit?.call(goal.id!);
                                      } else if (value == 'delete') {
                                        showDeleteConfirmationDialog(
                                          context: context,
                                          onDeleteConfirm: () {
                                            habitProvider.deleteGoal(goal.id!);
                                            onDelete?.call(goal.id!);
                                          },
                                        );
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

                              // Custom Gradient Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: double.infinity,
                                      color: const Color(0xFFEBEBEB),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progressRatio,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.orangeGradient,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Target Days Met Counter
                              Text(
                                "$currentProgress from $totalDays days target",
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Goal Frequency Tag
                              Text(
                                goal.habitType.isNotEmpty ? goal.habitType : goal.period,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}