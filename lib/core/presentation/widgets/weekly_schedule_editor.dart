import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../../data/models/day_schedule_model.dart';
import '../cubit/weekly_schedule_cubit.dart';

class WeeklyScheduleEditor extends StatelessWidget {
  final Map<String, DaySchedule> initialSchedule;
  final ValueChanged<Map<String, DaySchedule>> onScheduleChanged;

  const WeeklyScheduleEditor({
    super.key,
    required this.initialSchedule,
    required this.onScheduleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WeeklyScheduleCubit(initialSchedule),
      child: _WeeklyScheduleEditorView(
        initialSchedule: initialSchedule,
        onScheduleChanged: onScheduleChanged,
      ),
    );
  }
}

class _WeeklyScheduleEditorView extends StatelessWidget {
  final Map<String, DaySchedule> initialSchedule;
  final ValueChanged<Map<String, DaySchedule>> onScheduleChanged;

  const _WeeklyScheduleEditorView({
    required this.initialSchedule,
    required this.onScheduleChanged,
  });

  TimeOfDay _parseTime(
    String? timeStr, {
    TimeOfDay fallback = const TimeOfDay(hour: 9, minute: 0),
  }) {
    if (timeStr == null || timeStr.trim().isEmpty) return fallback;
    final clean = timeStr.trim().replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
    final parts = clean.split(':');
    if (parts.isNotEmpty) {
      final hour = int.tryParse(parts[0].trim());
      final minute = parts.length > 1 ? int.tryParse(parts[1].trim()) : 0;
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour < 24 &&
          minute >= 0 &&
          minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return fallback;
  }

  String _formatTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
              dialHandColor: AppColors.blue1,
              dialBackgroundColor: AppColors.blue3,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WeeklyScheduleCubit, WeeklyScheduleState>(
      listener: (context, state) {
        onScheduleChanged(state.schedule);
        if (state.notificationMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notificationMessage!),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.blue1,
            ),
          );
        }
      },
      builder: (context, state) {
        final schedule = state.schedule;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Schedule',
              style: TextStyles.headingSemiBold.copyWith(
                fontSize: 16,
                color: AppColors.blue1,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kDaysOfWeek.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final day = kDaysOfWeek[index];
                final isEnabled = schedule.containsKey(day);
                final daySchedule = schedule[day];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEnabled
                          ? AppColors.blue1.withValues(alpha: 0.6)
                          : AppColors.blue2.withValues(alpha: 0.2),
                      width: isEnabled ? 1.2 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isEnabled
                                      ? AppColors.blue1
                                      : AppColors.textMuted.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                day,
                                style: TextStyles.headingSemiBold.copyWith(
                                  fontSize: 15,
                                  color: isEnabled
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isEnabled
                                      ? AppColors.blue1.withValues(alpha: 0.15)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isEnabled
                                        ? AppColors.blue1.withValues(alpha: 0.5)
                                        : AppColors.textMuted.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  isEnabled ? 'Open' : 'Closed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isEnabled
                                        ? AppColors.blue1
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isEnabled,
                            activeThumbColor: AppColors.blue1,
                            activeTrackColor: AppColors.blue2,
                            inactiveThumbColor: AppColors.textMuted,
                            inactiveTrackColor: AppColors.blue3,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              context
                                  .read<WeeklyScheduleCubit>()
                                  .toggleDay(day, val);
                            },
                          ),
                        ],
                      ),
                      if (isEnabled && daySchedule != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeBox(
                                context: context,
                                label: 'Open',
                                timeString: daySchedule.open,
                                onTap: () async {
                                  final initial = _parseTime(
                                    daySchedule.open,
                                    fallback: const TimeOfDay(
                                      hour: 9,
                                      minute: 0,
                                    ),
                                  );
                                  final picked =
                                      await _pickTime(context, initial);
                                  if (picked != null) {
                                    context
                                        .read<WeeklyScheduleCubit>()
                                        .updateDaySchedule(
                                          day,
                                          daySchedule.copyWith(
                                            open: _formatTime(picked),
                                          ),
                                        );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimeBox(
                                context: context,
                                label: 'Close',
                                timeString: daySchedule.close,
                                onTap: () async {
                                  final initial = _parseTime(
                                    daySchedule.close,
                                    fallback: const TimeOfDay(
                                      hour: 17,
                                      minute: 0,
                                    ),
                                  );
                                  final picked =
                                      await _pickTime(context, initial);
                                  if (picked != null) {
                                    context
                                        .read<WeeklyScheduleCubit>()
                                        .updateDaySchedule(
                                          day,
                                          daySchedule.copyWith(
                                            close: _formatTime(picked),
                                          ),
                                        );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (daySchedule.breakStart != null &&
                            daySchedule.breakEnd != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeBox(
                                  context: context,
                                  label: 'Break Start',
                                  timeString: daySchedule.breakStart!,
                                  onTap: () async {
                                    final initial = _parseTime(
                                      daySchedule.breakStart,
                                      fallback: const TimeOfDay(
                                        hour: 13,
                                        minute: 0,
                                      ),
                                    );
                                    final picked =
                                        await _pickTime(context, initial);
                                    if (picked != null) {
                                      context
                                          .read<WeeklyScheduleCubit>()
                                          .updateDaySchedule(
                                            day,
                                            daySchedule.copyWith(
                                              breakStart: _formatTime(picked),
                                            ),
                                          );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimeBox(
                                  context: context,
                                  label: 'Break End',
                                  timeString: daySchedule.breakEnd!,
                                  onTap: () async {
                                    final initial = _parseTime(
                                      daySchedule.breakEnd,
                                      fallback: const TimeOfDay(
                                        hour: 14,
                                        minute: 0,
                                      ),
                                    );
                                    final picked =
                                        await _pickTime(context, initial);
                                    if (picked != null) {
                                      context
                                          .read<WeeklyScheduleCubit>()
                                          .updateDaySchedule(
                                            day,
                                            daySchedule.copyWith(
                                              breakEnd: _formatTime(picked),
                                            ),
                                          );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                context
                                    .read<WeeklyScheduleCubit>()
                                    .toggleBreakWindow(day);
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    daySchedule.breakStart != null &&
                                            daySchedule.breakEnd != null
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                    size: 14,
                                    color: AppColors.blue1,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    daySchedule.breakStart != null &&
                                            daySchedule.breakEnd != null
                                        ? 'Remove Break'
                                        : 'Add Break Window',
                                    style: TextStyles.labelRegular.copyWith(
                                      fontSize: 12,
                                      color: AppColors.blue1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (schedule.length > 1)
                              GestureDetector(
                                onTap: () {
                                  context
                                      .read<WeeklyScheduleCubit>()
                                      .applyToAllWorkingDays(day);
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.copy_rounded,
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Apply to all days',
                                      style: TextStyles.labelRegular.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeBox({
    required BuildContext context,
    required String label,
    required String timeString,
    required VoidCallback onTap,
  }) {
    final tod = _parseTime(timeString);
    final displayStr = tod.format(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blue3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.blue2.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyles.labelRegular.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayStr,
                  style: TextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
