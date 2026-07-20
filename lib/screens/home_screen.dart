import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

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
  HomeScreen({super.key});
  final ValueNotifier<List<HabitItem>> _habitsNotifier = ValueNotifier([
    HabitItem(title: "Meditating", isCompleted: true),
    HabitItem(title: "Read Philosophy", isCompleted: true),
    HabitItem(title: "Journaling", isCompleted: false),
  ]);

  final ValueNotifier<List<GoalItem>> _goalsNotifier = ValueNotifier([
    GoalItem(
      title: "Finish 5 Philosophy Books",
      progressValue: 0.7,
      progressText: "5 from 7 days target",
      frequency: "Everyday",
    ),
    GoalItem(
      title: "Sleep before 11 pm",
      progressValue: 0.7,
      progressText: "5 from 7 days target",
      frequency: "Everyday",
    ),
    GoalItem(
      title: "Finish read The Hobbits",
      progressValue: 0.5,
      progressText: "3 from 7 days target",
      frequency: "Everyday",
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Subheader
              Text(
                "Sun, 1 March 2022",
                style: GoogleFonts.nunito(
                  color: AppColors.blackGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        shaderCallback: (Rect bounds) {
                          return AppColors.orangeGradient.createShader(bounds);
                        },
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
                ],
              ),
              const SizedBox(height: 20),

              // Progress Banner Card
              Container(
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
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
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
                                    value: 0.7,
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
                                        "70%",
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
                                  "3 of 5 habits",
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Today Habit Container
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
                          onPressed: () {},
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return AppColors.orangeGradient.createShader(bounds);
                            },
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
                    ValueListenableBuilder<List<HabitItem>>(
                      valueListenable: _habitsNotifier,
                      builder: (context, habits, child) {
                        return ListView.separated(
                          itemCount: habits.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final habit = habits[index];
                            return _buildHabitCard(
                              title: habit.title,
                              isCompleted: habit.isCompleted,
                              onToggle: () {
                                habit.isCompleted = !habit.isCompleted;
                                _habitsNotifier.value = List.from(habits);
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

              // Your Goals Container with ListView.builder
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
                          onPressed: () {},
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return AppColors.orangeGradient.createShader(bounds);
                            },
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
                    ValueListenableBuilder<List<GoalItem>>(
                      valueListenable: _goalsNotifier,
                      builder: (context, goals, child) {
                        return ListView.separated(
                          itemCount: goals.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final goal = goals[index];
                            return _buildGoalCard(
                              title: goal.title,
                              progressValue: goal.progressValue,
                              progressText: goal.progressText,
                              frequency: goal.frequency,
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
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 38, weight: 4),
        ),
      ),
    );
  }

  Widget _buildHabitCard({
    required String title,
    required bool isCompleted,
    required VoidCallback onToggle,
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
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF37C871) : AppColors.blackGrey,
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
              const SizedBox(width: 12),
              const Icon(Icons.more_vert, size: 20, color: AppColors.blackGrey),
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
              Icon(Icons.more_vert, size: 20, color: AppColors.blackGrey),
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