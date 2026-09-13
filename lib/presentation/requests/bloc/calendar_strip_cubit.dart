import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class CalendarStripState extends Equatable {
  final DateTime focusedWeekStart;

  const CalendarStripState({required this.focusedWeekStart});

  @override
  List<Object?> get props => [focusedWeekStart];
}

class CalendarStripCubit extends Cubit<CalendarStripState> {
  CalendarStripCubit({DateTime? initialDate})
      : super(CalendarStripState(
          focusedWeekStart: _getWeekStart(initialDate ?? DateTime.now()),
        ));

  static DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(
      Duration(days: dayOfWeek - 1),
    );
  }

  void previousWeek() {
    emit(CalendarStripState(
      focusedWeekStart: state.focusedWeekStart.subtract(const Duration(days: 7)),
    ));
  }

  void nextWeek() {
    emit(CalendarStripState(
      focusedWeekStart: state.focusedWeekStart.add(const Duration(days: 7)),
    ));
  }

  void goToDate(DateTime date) {
    emit(CalendarStripState(
      focusedWeekStart: _getWeekStart(date),
    ));
  }

  void syncWithSelectedDate(DateTime? selectedDate) {
    if (selectedDate == null) return;
    final start = DateTime(
      state.focusedWeekStart.year,
      state.focusedWeekStart.month,
      state.focusedWeekStart.day,
    );
    final end = start.add(const Duration(days: 7));
    final isInWeek = (selectedDate.isAfter(start) || selectedDate.isAtSameMomentAs(start)) &&
        selectedDate.isBefore(end);
    if (!isInWeek) {
      goToDate(selectedDate);
    }
  }
}
