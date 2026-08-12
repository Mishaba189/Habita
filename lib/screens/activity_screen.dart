import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constants/app_colors.dart';

enum _CalendarViewMode { days, months, years }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedDateRangeText = 'This Month';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        DateTime tempFocusedDay = _focusedDay;
        DateTime? tempSelectedDay = _selectedDay;
        DateTime? tempRangeStart = _rangeStart;
        DateTime? tempRangeEnd = _rangeEnd;
        _CalendarViewMode viewMode = _CalendarViewMode.days;

        final List<String> monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];

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
                                tempFocusedDay = DateTime(tempFocusedDay.year - 1);
                              } else {
                                tempFocusedDay = DateTime(tempFocusedDay.year - 12);
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
                                tempFocusedDay = DateTime(tempFocusedDay.year + 1);
                              } else {
                                tempFocusedDay = DateTime(tempFocusedDay.year + 12);
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
                          rangeHighlightColor: AppColors.green.withOpacity(0.15),
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
                          onPressed: () {
                            setState(() {
                              _selectedDay = null;
                              _rangeStart = null;
                              _rangeEnd = null;
                              _selectedDateRangeText = 'This Month';
                            });
                            Navigator.pop(context);
                          },
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(0, 36), // Reduces standard height
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces touch target padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _focusedDay = tempFocusedDay;
                                _selectedDay = tempSelectedDay;
                                _rangeStart = tempRangeStart;
                                _rangeEnd = tempRangeEnd;

                                final List<String> monthAbbrs = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];

                                String formatDate(DateTime date) =>
                                    "${date.day} ${monthAbbrs[date.month - 1]} ${date.year}";

                                if (_rangeStart != null && _rangeEnd != null) {
                                  _selectedDateRangeText =
                                  "${formatDate(_rangeStart!)} - ${formatDate(_rangeEnd!)}";
                                } else if (_rangeStart != null) {
                                  _selectedDateRangeText = formatDate(_rangeStart!);
                                } else if (_selectedDay != null) {
                                  _selectedDateRangeText = formatDate(_selectedDay!);
                                } else {
                                  _selectedDateRangeText = 'This Month';
                                }
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Apply',
                              style: GoogleFonts.nunito(
                                fontSize: 13, // Scaled down font size to match smaller footprint
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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

              // Progress Report Header with Date Selector Dropdown
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
                    onTap: _showCalendarDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedDateRangeText,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blackGrey,
                            ),
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

              // Main Card Container
              Container(
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
                          onTap: () {},
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
                    const SizedBox(height: 24),

                    // Donut Progress Indicator
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(190, 190),
                            painter: _DonutChartPainter(progress: 0.60),
                          ),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) {
                              return AppColors.orangeGradient.createShader(bounds);
                            },
                            child: Text(
                              '60%',
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
                    const SizedBox(height: 24),

                    // Goal Status Summaries
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (Rect bounds) {
                        return AppColors.orangeGradient.createShader(bounds);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '11 Habits goal has achieved',
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
                        const Icon(Icons.close, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "6 Habits goal hasn't achieved",
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Habit Items List
                    _buildHabitTile(
                      progressPercentage: '100%',
                      title: 'Journaling everyday',
                      subtitle: '7 from 7 days target',
                      isAchieved: true,
                    ),
                    const SizedBox(height: 12),
                    _buildHabitTile(
                      progressPercentage: '100%',
                      title: 'Cooking Practice',
                      subtitle: '7 from 7 days target',
                      isAchieved: true,
                    ),
                    const SizedBox(height: 12),
                    _buildHabitTile(
                      progressPercentage: '70%',
                      title: 'Vitamin',
                      subtitle: '5 from 7 days target',
                      isAchieved: false,
                    ),
                    const SizedBox(height: 20),

                    // Bottom Link
                    TextButton(
                      onPressed: () {},
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) =>
                            AppColors.orangeGradient.createShader(bounds),
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
    final Color activeColor =
    isAchieved ? const Color(0xFF37C871) : const Color(0xFFB0B0B0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Circular progress ring indicator on left
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor,
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                progressPercentage,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
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

          // Right Tag / Status
          if (isAchieved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F8EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Achieved',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF37C871),
                ),
              ),
            )
          else
            Text(
              'Unachieved',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}


// Custom Painter for main Donut Chart
class _DonutChartPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

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
      ..strokeCap = StrokeCap.round;

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