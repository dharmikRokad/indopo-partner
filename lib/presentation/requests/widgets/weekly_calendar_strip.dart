import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class WeeklyCalendarStrip extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const WeeklyCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<WeeklyCalendarStrip> createState() => _WeeklyCalendarStripState();
}

class _WeeklyCalendarStripState extends State<WeeklyCalendarStrip> {
  late DateTime _focusedWeekStart;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _focusedWeekStart = _getWeekStart(widget.selectedDate ?? DateTime.now());
  }

  @override
  void didUpdateWidget(covariant WeeklyCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != null &&
        !_isSameWeek(widget.selectedDate!, _focusedWeekStart)) {
      setState(() {
        _focusedWeekStart = _getWeekStart(widget.selectedDate!);
      });
    }
  }

  DateTime _getWeekStart(DateTime date) {
    // 1 = Monday, 7 = Sunday
    final dayOfWeek = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(
      Duration(days: dayOfWeek - 1),
    );
  }

  bool _isSameWeek(DateTime date, DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        date.isBefore(end);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> _getDaysOfWeek() {
    return List.generate(7, (index) {
      return _focusedWeekStart.add(Duration(days: index));
    });
  }

  void _previousWeek() {
    setState(() {
      _focusedWeekStart = _focusedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _focusedWeekStart = _focusedWeekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _focusedWeekStart = _getWeekStart(today);
    });
    widget.onDateSelected(today);
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysOfWeek();
    final today = DateTime.now();
    final currentMonthName = _monthNames[_focusedWeekStart.month - 1];
    final currentYear = _focusedWeekStart.year;

    final isFiltered = widget.selectedDate != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue2.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Month/Year and Controls
          Row(
            children: [
              Text(
                '$currentMonthName $currentYear',
                style: TextStyles.headingSemiBold.copyWith(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => widget.onDateSelected(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.blue1.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show All',
                          style: TextStyles.labelRegular.copyWith(
                            fontSize: 11,
                            color: AppColors.blue1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: AppColors.blue1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Today shortcut button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                icon: const Icon(
                  Icons.today_rounded,
                  color: AppColors.blue1,
                ),
                tooltip: 'Today',
                onPressed: _goToToday,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white70,
                ),
                onPressed: _previousWeek,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                ),
                onPressed: _nextWeek,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Days Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isSelected = _isSameDay(day, widget.selectedDate);
              final isTodayDay = _isSameDay(day, today);
              final dayName = _dayNames[day.weekday - 1];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (isSelected) {
                          widget.onDateSelected(null); // Toggle off
                        } else {
                          widget.onDateSelected(day);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.blue1
                              : AppColors.blue3.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.blue1
                                : isTodayDay
                                    ? AppColors.blue1.withValues(alpha: 0.8)
                                    : AppColors.blue2.withValues(alpha: 0.2),
                            width: isSelected || isTodayDay ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayName,
                              style: TextStyles.labelRegular.copyWith(
                                fontSize: 11,
                                color: isSelected
                                    ? AppColors.blue3
                                    : AppColors.textMuted,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              style: TextStyles.headingBold.copyWith(
                                fontSize: 15,
                                color: isSelected
                                    ? AppColors.blue3
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Today indicator dot
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isTodayDay
                                    ? (isSelected
                                        ? AppColors.blue3
                                        : AppColors.blue1)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
