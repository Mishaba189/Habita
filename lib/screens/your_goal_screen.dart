import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/create_habit_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_state.dart';
import 'goal_detail_screen.dart';


class YourGoalsScreen extends StatelessWidget {
  final Function(String goalId)? onEdit;
  final Function(String goalId)? onDelete;

  const YourGoalsScreen({
    super.key,
    this.onEdit,
    this.onDelete,
  });

  /// Helper to calculate current progress directly from completed dates count
  int _calculateCompletedDaysProgress(List<String> completedDates, int totalDays) {
    return completedDates.length.clamp(0, totalDays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
              // Goals List Consumer
              Expanded(
                child: Consumer<HabitProvider>(
                  builder: (context, habitProvider, child) {
                    if (habitProvider.goals.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: buildEmptyState(
                            icon: Icons.track_changes_rounded,
                            title: "No Goals Created Yet",
                            subtitle: "Start setting up your personal goals to track your daily progress.",
                            buttonText: "Add Goal",
                            onButtonPressed: () {
                              showCreateHabitDialog(context);
                            },
                          ),
                        ),
                      );
                    }

                    // Sort goals so the newest created ones appear first
                    final sortedGoals = List<HabitModel>.from(habitProvider.goals)
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return ListView.separated(
                      itemCount: sortedGoals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final HabitModel goal = sortedGoals[index];

                        // Calculate target based on habit type + period
                        final int totalDays = habitProvider.calculateTargetDays(goal);

                        // Calculate how many target days have been completed
                        final int currentProgress =
                        _calculateCompletedDaysProgress(
                          goal.completedDates,
                          totalDays,
                        );

                        final double progressRatio = totalDays > 0
                            ? (currentProgress / totalDays).clamp(0.0, 1.0)
                            : 0.0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GoalDetailsScreen(habit: goal),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEDEDED)),
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
                                          fontSize: 16,
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
                                          showCreateHabitDialog(
                                            context,
                                            isEdit: true,
                                            goal: goal,
                                          );
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
                                const SizedBox(height: 5),

                                // Custom Gradient Progress Bar
                                Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 13,
                                          width: double.infinity,
                                          color: const Color(0xFFEBEBEB),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: progressRatio,
                                          child: Container(
                                            height: 13,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.orangeGradient,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Target Days Met Counter
                                Text(
                                  "$currentProgress from $totalDays days target",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.blackGrey,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Goal Frequency Tag
                                Text(
                                  goal.habitType.isNotEmpty ? goal.habitType : goal.period,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.orange,
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
              )
            ],
          ),
        ),
      ),
    );
  }
}