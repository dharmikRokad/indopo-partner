import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/day_schedule_model.dart';

class WeeklyScheduleState extends Equatable {
  final Map<String, DaySchedule> schedule;
  final String? notificationMessage;

  const WeeklyScheduleState({
    required this.schedule,
    this.notificationMessage,
  });

  WeeklyScheduleState copyWith({
    Map<String, DaySchedule>? schedule,
    String? notificationMessage,
  }) {
    return WeeklyScheduleState(
      schedule: schedule ?? this.schedule,
      notificationMessage: notificationMessage,
    );
  }

  @override
  List<Object?> get props => [schedule, notificationMessage];
}

class WeeklyScheduleCubit extends Cubit<WeeklyScheduleState> {
  WeeklyScheduleCubit(Map<String, DaySchedule> initialSchedule)
      : super(WeeklyScheduleState(
          schedule: Map<String, DaySchedule>.from(initialSchedule),
        ));

  void updateScheduleFromWidget(Map<String, DaySchedule> newSchedule) {
    if (newSchedule != state.schedule) {
      emit(state.copyWith(
        schedule: Map<String, DaySchedule>.from(newSchedule),
        notificationMessage: null,
      ));
    }
  }

  void toggleDay(String day, bool enabled) {
    final newMap = Map<String, DaySchedule>.from(state.schedule);
    if (enabled) {
      DaySchedule template = const DaySchedule(open: '09:00', close: '17:00');
      if (newMap.isNotEmpty) {
        template = newMap.values.last;
      }
      newMap[day] = DaySchedule(
        open: template.open,
        close: template.close,
        breakStart: template.breakStart,
        breakEnd: template.breakEnd,
      );
    } else {
      newMap.remove(day);
    }
    emit(state.copyWith(schedule: newMap, notificationMessage: null));
  }

  void updateDaySchedule(String day, DaySchedule daySchedule) {
    final newMap = Map<String, DaySchedule>.from(state.schedule);
    newMap[day] = daySchedule;
    emit(state.copyWith(schedule: newMap, notificationMessage: null));
  }

  void toggleBreakWindow(String day) {
    final newMap = Map<String, DaySchedule>.from(state.schedule);
    final daySchedule = newMap[day];
    if (daySchedule == null) return;

    if (daySchedule.breakStart != null && daySchedule.breakEnd != null) {
      newMap[day] = DaySchedule(
        open: daySchedule.open,
        close: daySchedule.close,
        breakStart: null,
        breakEnd: null,
      );
    } else {
      newMap[day] = daySchedule.copyWith(
        breakStart: '13:00',
        breakEnd: '14:00',
      );
    }
    emit(state.copyWith(schedule: newMap, notificationMessage: null));
  }

  void applyToAllWorkingDays(String sourceDay) {
    final source = state.schedule[sourceDay];
    if (source == null) return;

    final newMap = Map<String, DaySchedule>.from(state.schedule);
    for (final day in kDaysOfWeek) {
      if (newMap.containsKey(day)) {
        newMap[day] = DaySchedule(
          open: source.open,
          close: source.close,
          breakStart: source.breakStart,
          breakEnd: source.breakEnd,
        );
      }
    }

    emit(state.copyWith(
      schedule: newMap,
      notificationMessage: "Applied $sourceDay's hours to all active days",
    ));
  }

  void quickSelectWeekdays() {
    final newMap = <String, DaySchedule>{};
    for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
      newMap[day] = const DaySchedule(open: '09:00', close: '17:00');
    }
    emit(state.copyWith(schedule: newMap, notificationMessage: null));
  }

  void quickSelectAllDays() {
    final newMap = <String, DaySchedule>{};
    for (final day in kDaysOfWeek) {
      newMap[day] = const DaySchedule(open: '09:00', close: '17:00');
    }
    emit(state.copyWith(schedule: newMap, notificationMessage: null));
  }
}
