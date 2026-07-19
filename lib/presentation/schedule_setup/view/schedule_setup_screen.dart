import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/profile_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class ScheduleSetupScreen extends StatefulWidget {
  const ScheduleSetupScreen({super.key});

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> {
  final List<String> _daysOfWeek = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final List<String> _selectedDays = [];

  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate if values exist (in case redirect occurs and some fields exist)
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final partner = authState.partner;
      if (partner.workingDays != null) {
        _selectedDays.addAll(partner.workingDays!);
      }
      _openTime = _parseTimeString(partner.openTime);
      _closeTime = _parseTimeString(partner.closeTime);
    }
  }

  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> _selectTime({required bool isOpenTime}) async {
    final initialTime = isOpenTime
        ? (_openTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_closeTime ?? const TimeOfDay(hour: 18, minute: 0));

    final TimeOfDay? picked = await showTimePicker(
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

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  double _timeOfDayToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  Future<void> _submitSchedule(PartnerModel partner) async {
    // Validations
    if (_selectedDays.isEmpty) {
      AppSnackBar.showWarning(context, 'Please select at least one working day');
      return;
    }
    if (_openTime == null) {
      AppSnackBar.showWarning(context, 'Please select an opening time');
      return;
    }
    if (_closeTime == null) {
      AppSnackBar.showWarning(context, 'Please select a closing time');
      return;
    }

    if (_timeOfDayToDouble(_openTime!) >= _timeOfDayToDouble(_closeTime!)) {
      AppSnackBar.showWarning(context, 'Opening time must be earlier than closing time');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPartner = partner.copyWith(
        workingDays: _selectedDays,
        openTime: _formatTimeOfDay(_openTime!),
        closeTime: _formatTimeOfDay(_closeTime!),
      );

      final savedPartner = await context.read<ProfileRepository>().saveProfile(updatedPartner);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Schedule configured successfully!');
        context.read<AuthBloc>().add(PartnerUpdated(savedPartner));
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save schedule: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final partner = authState.partner;

    return Scaffold(
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Schedule Setup', style: TextStyles.headingSemiBold),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header description card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.blue2.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.blue1,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Configure Working Hours',
                      style: TextStyles.headingBold.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please specify the working days and opening/closing hours of your practice so patients can request appointments.',
                      style: TextStyles.labelRegular.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Working Days Section
              Text('Working Days', style: TextStyles.headingSemiBold.copyWith(fontSize: 16, color: AppColors.blue1)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _daysOfWeek.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      selectedColor: AppColors.blue2,
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.blue3,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.blue1 : AppColors.blue2.withValues(alpha: 0.3),
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Open / Close Time Section
              Text('Working Hours', style: TextStyles.headingSemiBold.copyWith(fontSize: 16, color: AppColors.blue1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'Opening Time',
                      time: _openTime,
                      onTap: () => _selectTime(isOpenTime: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'Closing Time',
                      time: _closeTime,
                      onTap: () => _selectTime(isOpenTime: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Submit Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.blue1, AppColors.blue2],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitSchedule(partner),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save & Continue',
                          style: TextStyles.headingBold.copyWith(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.headingSemiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue2.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null ? time.format(context) : 'Select Time',
                  style: TextStyle(
                    color: time != null ? Colors.white : AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
                const Icon(Icons.access_time_rounded, color: AppColors.blue1, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
