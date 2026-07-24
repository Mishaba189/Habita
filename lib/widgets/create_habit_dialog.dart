import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habita/screens/success_page.dart';

import '../constants/app_colors.dart';

void showCreateHabitDialog(BuildContext context) {
  final TextEditingController goalController = TextEditingController();
  final TextEditingController habitNameController = TextEditingController();
  final TextEditingController customPeriodController = TextEditingController();

  // Expanded options list including 'Custom'
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
    'Random'
  ];

  // Days of the week list for the multi-select grid
  final List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // State variables for selected options
  String selectedPeriod = '1 Month (30 Days)';
  String selectedHabitType = 'Everyday';

  // Set to track multiple selected days when 'Specific Days' is active
  final Set<String> selectedSpecificDays = {'Mon', 'Wed', 'Fri'};

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                    // Header Row with Title and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Create New Habit Goal",
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackGrey,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.close, size: 18, color: AppColors.blackGrey),
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
                      decoration: InputDecoration(
                        hintText: "e.g., Finish 5 Philosophy Books",
                        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFEDEDED)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
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
                      decoration: InputDecoration(
                        hintText: "e.g., Read 15 pages",
                        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFEDEDED)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
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
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.yellow : Colors.white,
                                // gradient: isSelected ? AppColors.orangeGradient : null,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.orange : const Color(0xFFDEDEDE),
                                ),
                              ),
                              child: Text(
                                period,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.orange : AppColors.blackGrey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Conditionally show custom period text field
                    if (selectedPeriod == 'Custom') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customPeriodController,
                        style: GoogleFonts.nunito(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Enter custom period (e.g., 45 Days)",
                          hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEDEDED)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Habit Type Selection Chips/List
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
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.yellow : Colors.white,
                              // gradient: isSelected ? AppColors.orangeGradient : null,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.orange : const Color(0xFFDEDEDE),
                              ),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColors.orange : AppColors.blackGrey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Conditionally show Specific Days multi-select grid
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
                              "Select Active Days",
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
                                final isDaySelected = selectedSpecificDays.contains(day);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isDaySelected) {
                                        selectedSpecificDays.remove(day);
                                      } else {
                                        selectedSpecificDays.add(day);
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDaySelected ? AppColors.yellow : Colors.white,
                                      // gradient: isDaySelected ? AppColors.orangeGradient : null,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDaySelected ? AppColors.orange : const Color(0xFFDEDEDE),
                                      ),
                                    ),
                                    child: Text(
                                      day[0],
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDaySelected ? AppColors.orange : AppColors.blackGrey,
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
                    const SizedBox(height: 24),

                    // Create New Gradient Button
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
                        onPressed: () {
                          // Resolve final values
                          final finalPeriod = selectedPeriod == 'Custom'
                              ? customPeriodController.text.trim()
                              : selectedPeriod;

                          final finalType = selectedHabitType == 'Specific Days'
                              ? 'Specific Days: ${selectedSpecificDays.join(", ")}'
                              : selectedHabitType;

                          debugPrint("Goal: ${goalController.text}");
                          debugPrint("Habit: ${habitNameController.text}");
                          debugPrint("Period: $finalPeriod");
                          debugPrint("Type: $finalType");
                          Navigator.pop(context);

                          Navigator.push(context, MaterialPageRoute(builder: (_) => HabitSuccessScreen()));
                        },
                        child: Text(
                          "Create New",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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