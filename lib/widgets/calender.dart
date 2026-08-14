import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constants/app_colors.dart';


enum _CalendarViewMode { days, months, years }

void showCalendarDialog({
  required BuildContext context,
  required DateTime initialFocusedDay,
  required DateTime? initialSelectedDay,
  required DateTime? initialRangeStart,
  required DateTime? initialRangeEnd,
  required VoidCallback onClearFilter,
  required Function(DateTime focusedDay, DateTime? selectedDay,
      DateTime? rangeStart, DateTime? rangeEnd)
  onApply,
}) {
  DateTime tempFocusedDay = initialFocusedDay;
  DateTime? tempSelectedDay = initialSelectedDay;
  DateTime? tempRangeStart = initialRangeStart;
  DateTime? tempRangeEnd = initialRangeEnd;
  _CalendarViewMode viewMode = _CalendarViewMode.days;

  final List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          int startYear = (tempFocusedDay.year ~/ 12) * 12;
          int endYear = startYear + 11;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Custom Navigation Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setDialogState(() {
                            if (viewMode == _CalendarViewMode.days) {
                              tempFocusedDay = DateTime(
                                tempFocusedDay.year,
                                tempFocusedDay.month - 1,
                              );
                            } else if (viewMode == _CalendarViewMode.months) {
                              tempFocusedDay =
                                  DateTime(tempFocusedDay.year - 1);
                            } else {
                              tempFocusedDay =
                                  DateTime(tempFocusedDay.year - 12);
                            }
                          });
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (viewMode == _CalendarViewMode.days) {
                              viewMode = _CalendarViewMode.months;
                            } else if (viewMode == _CalendarViewMode.months) {
                              viewMode = _CalendarViewMode.years;
                            }
                          });
                        },
                        child: Text(
                          viewMode == _CalendarViewMode.days
                              ? '${monthNames[tempFocusedDay.month - 1]} ${tempFocusedDay.year}'
                              : viewMode == _CalendarViewMode.months
                              ? '${tempFocusedDay.year}'
                              : '$startYear - $endYear',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackGrey,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setDialogState(() {
                            if (viewMode == _CalendarViewMode.days) {
                              tempFocusedDay = DateTime(
                                tempFocusedDay.year,
                                tempFocusedDay.month + 1,
                              );
                            } else if (viewMode == _CalendarViewMode.months) {
                              tempFocusedDay =
                                  DateTime(tempFocusedDay.year + 1);
                            } else {
                              tempFocusedDay =
                                  DateTime(tempFocusedDay.year + 12);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- Dynamic Body Content based on viewMode ---
                  if (viewMode == _CalendarViewMode.days)
                    TableCalendar(
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2050, 12, 31),
                      focusedDay: tempFocusedDay,
                      headerVisible: false,
                      rangeSelectionMode: RangeSelectionMode.toggledOn,
                      selectedDayPredicate: (day) =>
                          isSameDay(tempSelectedDay, day),
                      rangeStartDay: tempRangeStart,
                      rangeEndDay: tempRangeEnd,
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        rangeStartDecoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        rangeHighlightColor:
                        AppColors.green.withOpacity(0.15),
                        withinRangeTextStyle: GoogleFonts.nunito(
                          color: AppColors.blackGrey,
                        ),
                        defaultTextStyle: GoogleFonts.nunito(),
                        weekendTextStyle:
                        GoogleFonts.nunito(color: AppColors.green),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setDialogState(() {
                          tempSelectedDay = selectedDay;
                          tempFocusedDay = focusedDay;
                          tempRangeStart = null;
                          tempRangeEnd = null;
                        });
                      },
                      onRangeSelected: (start, end, focusedDay) {
                        setDialogState(() {
                          tempSelectedDay = null;
                          tempRangeStart = start;
                          tempRangeEnd = end;
                          tempFocusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        tempFocusedDay = focusedDay;
                      },
                    )
                  else if (viewMode == _CalendarViewMode.months)
                    SizedBox(
                      height: 240,
                      child: GridView.builder(
                        itemCount: 12,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.8,
                        ),
                        itemBuilder: (context, index) {
                          final isSelected =
                              tempFocusedDay.month == index + 1;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setDialogState(() {
                                tempFocusedDay = DateTime(
                                  tempFocusedDay.year,
                                  index + 1,
                                );
                                viewMode = _CalendarViewMode.days;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.green
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                monthNames[index],
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.blackGrey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    SizedBox(
                      height: 240,
                      child: GridView.builder(
                        itemCount: 12,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.8,
                        ),
                        itemBuilder: (context, index) {
                          final year = startYear + index;
                          final isSelected = tempFocusedDay.year == year;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setDialogState(() {
                                tempFocusedDay = DateTime(
                                  year,
                                  tempFocusedDay.month,
                                );
                                viewMode = _CalendarViewMode.months;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.green
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$year',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.blackGrey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),

                  // --- Bottom Action Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Clear Filter Button
                      TextButton(
                        onPressed: onClearFilter,
                        child: Text(
                          'Clear Filter',
                          style: GoogleFonts.nunito(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Gradient Apply Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.greenGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            onApply(
                              tempFocusedDay,
                              tempSelectedDay,
                              tempRangeStart,
                              tempRangeEnd,
                            );
                          },
                          child: Text(
                            'Apply',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
