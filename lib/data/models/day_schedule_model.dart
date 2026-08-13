class DaySchedule {
  final String open; // "HH:MM" (24-hour format)
  final String close; // "HH:MM" (24-hour format)
  final String? breakStart; // "HH:MM" (optional)
  final String? breakEnd; // "HH:MM" (optional)

  const DaySchedule({
    required this.open,
    required this.close,
    this.breakStart,
    this.breakEnd,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      open: json['open']?.toString() ?? '09:00',
      close: json['close']?.toString() ?? '17:00',
      breakStart:
          json['breakStart']?.toString() ?? json['break_start']?.toString(),
      breakEnd: json['breakEnd']?.toString() ?? json['break_end']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      if (breakStart != null && breakStart!.trim().isNotEmpty)
        'breakStart': breakStart!.trim(),
      if (breakEnd != null && breakEnd!.trim().isNotEmpty)
        'breakEnd': breakEnd!.trim(),
    };
  }

  DaySchedule copyWith({
    String? open,
    String? close,
    String? breakStart,
    String? breakEnd,
  }) {
    return DaySchedule(
      open: open ?? this.open,
      close: close ?? this.close,
      breakStart: breakStart ?? this.breakStart,
      breakEnd: breakEnd ?? this.breakEnd,
    );
  }

  @override
  String toString() {
    if (breakStart != null &&
        breakStart!.isNotEmpty &&
        breakEnd != null &&
        breakEnd!.isNotEmpty) {
      return '$open - $close (Break: $breakStart - $breakEnd)';
    }
    return '$open - $close';
  }
}

const List<String> kDaysOfWeek = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Converts 3-letter abbreviation or uppercase day name to standard full name
String normalizeDayName(String day) {
  final clean = day.trim().toUpperCase();
  switch (clean) {
    case 'MON':
    case 'MONDAY':
      return 'Monday';
    case 'TUE':
    case 'TUESDAY':
      return 'Tuesday';
    case 'WED':
    case 'WEDNESDAY':
      return 'Wednesday';
    case 'THU':
    case 'THURSDAY':
      return 'Thursday';
    case 'FRI':
    case 'FRIDAY':
      return 'Friday';
    case 'SAT':
    case 'SATURDAY':
      return 'Saturday';
    case 'SUN':
    case 'SUNDAY':
      return 'Sunday';
    default:
      if (day.isNotEmpty) {
        return day[0].toUpperCase() + day.substring(1).toLowerCase();
      }
      return day;
  }
}
