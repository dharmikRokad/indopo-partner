import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/presentation/widgets/logout_confirmation_dialog.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/presentation/widgets/address_autocomplete_field.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/profile_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class ScheduleSetupScreenState {
  final List<String> selectedDays;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final String address;
  final double? lat;
  final double? long;
  final bool isLoading;

  const ScheduleSetupScreenState({
    this.selectedDays = const [],
    this.openTime,
    this.closeTime,
    this.address = '',
    this.lat,
    this.long,
    this.isLoading = false,
  });

  ScheduleSetupScreenState copyWith({
    List<String>? selectedDays,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    String? address,
    double? lat,
    double? long,
    bool? isLoading,
  }) {
    return ScheduleSetupScreenState(
      selectedDays: selectedDays ?? this.selectedDays,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ScheduleSetupScreen extends StatefulWidget {
  const ScheduleSetupScreen({super.key});

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> {
  final List<String> _daysOfWeek = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final _stateCubit = ValueCubit<ScheduleSetupScreenState>(const ScheduleSetupScreenState());
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate if values exist (in case redirect occurs and some fields exist)
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthBlocStatus.authenticated && authState.partner != null) {
      final partner = authState.partner!;
      final selectedDays = <String>[];
      if (partner.workingDays != null) {
        selectedDays.addAll(partner.workingDays!);
      }
      final openTime = _parseTimeString(partner.openTime);
      final closeTime = _parseTimeString(partner.closeTime);
      final address = partner.details['address'] as String? ?? '';
      _addressController.text = address;
      _stateCubit.update(ScheduleSetupScreenState(
        selectedDays: selectedDays,
        openTime: openTime,
        closeTime: closeTime,
        address: address,
        lat: partner.lat,
        long: partner.long,
      ));
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _stateCubit.close();
    super.dispose();
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
    final currentState = _stateCubit.state;
    final initialTime = isOpenTime
        ? (currentState.openTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (currentState.closeTime ?? const TimeOfDay(hour: 18, minute: 0));

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
      if (isOpenTime) {
        _stateCubit.update(currentState.copyWith(openTime: picked));
      } else {
        _stateCubit.update(currentState.copyWith(closeTime: picked));
      }
    }
  }

  double _timeOfDayToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  Future<void> _submitSchedule(PartnerModel partner) async {
    final currentState = _stateCubit.state;
    // Validations
    if (currentState.address.trim().isEmpty) {
      AppSnackBar.showWarning(context, 'Please specify your physical address');
      return;
    }
    if (currentState.selectedDays.isEmpty) {
      AppSnackBar.showWarning(context, 'Please select at least one working day');
      return;
    }
    if (currentState.openTime == null) {
      AppSnackBar.showWarning(context, 'Please select an opening time');
      return;
    }
    if (currentState.closeTime == null) {
      AppSnackBar.showWarning(context, 'Please select a closing time');
      return;
    }

    if (_timeOfDayToDouble(currentState.openTime!) >= _timeOfDayToDouble(currentState.closeTime!)) {
      AppSnackBar.showWarning(context, 'Opening time must be earlier than closing time');
      return;
    }

    _stateCubit.update(currentState.copyWith(isLoading: true));

    try {
      final updatedDetails = Map<String, dynamic>.from(partner.details)
        ..['address'] = currentState.address.trim();

      final updatedPartner = partner.copyWith(
        workingDays: currentState.selectedDays,
        openTime: _formatTimeOfDay(currentState.openTime!),
        closeTime: _formatTimeOfDay(currentState.closeTime!),
        details: updatedDetails,
        lat: currentState.lat,
        long: currentState.long,
        orgAddress: currentState.address.trim(),
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
        _stateCubit.update(_stateCubit.state.copyWith(isLoading: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState.status != AuthBlocStatus.authenticated ||
        authState.partner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final partner = authState.partner!;

    return BlocBuilder<ValueCubit<ScheduleSetupScreenState>, ScheduleSetupScreenState>(
      bloc: _stateCubit,
      builder: (context, state) {
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
                onPressed: () async {
                  final shouldLogout = await LogoutConfirmationDialog.show(context);
                  if (shouldLogout == true && context.mounted) {
                    context.read<AuthBloc>().add(LogoutRequested());
                  }
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

                  // Physical Address Section
                  AddressAutocompleteField(
                    controller: _addressController,
                    label: 'Physical Address',
                    hint: 'Enter your physical address',
                    onLocationChanged: (address, lat, long) {
                      _stateCubit.update(_stateCubit.state.copyWith(
                        address: address,
                        lat: lat,
                        long: long,
                      ));
                    },
                    validator: (v) => v == null || v.trim().isEmpty ? 'Physical address is required' : null,
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
                        final isSelected = state.selectedDays.contains(day);
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
                            final list = List<String>.from(state.selectedDays);
                            if (selected) {
                              list.add(day);
                            } else {
                              list.remove(day);
                            }
                            _stateCubit.update(state.copyWith(selectedDays: list));
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
                          time: state.openTime,
                          onTap: () => _selectTime(isOpenTime: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'Closing Time',
                          time: state.closeTime,
                          onTap: () => _selectTime(isOpenTime: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // CTA Submit Button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [AppColors.blue1, AppColors.blue2],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : () => _submitSchedule(partner),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
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
      },
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
