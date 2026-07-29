import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/request_repo.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class AssignAppointmentState {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  const AssignAppointmentState({this.selectedDate, this.selectedTime});

  AssignAppointmentState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
  }) {
    return AssignAppointmentState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
    );
  }
}

class AssignAppointmentDialog extends StatelessWidget {
  final String requestId;
  final ValueChanged<AppointmentModel> onConfirmed;

  const AssignAppointmentDialog({
    super.key,
    required this.requestId,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppointmentBloc(
        requestRepository: context.read<RequestRepository>(),
      ),
      child: _AssignAppointmentContent(
        requestId: requestId,
        onConfirmed: onConfirmed,
      ),
    );
  }
}

class _AssignAppointmentContent extends StatefulWidget {
  final String requestId;
  final ValueChanged<AppointmentModel> onConfirmed;

  const _AssignAppointmentContent({
    required this.requestId,
    required this.onConfirmed,
  });

  @override
  State<_AssignAppointmentContent> createState() => _AssignAppointmentContentState();
}

class _AssignAppointmentContentState extends State<_AssignAppointmentContent> {
  final _formKey = GlobalKey<FormState>();
  final _aptNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _stateCubit = ValueCubit<AssignAppointmentState>(const AssignAppointmentState());

  @override
  void initState() {
    super.initState();
    // Auto-generate a random appointment number suggestion
    final randomDigits = Random().nextInt(9000) + 1000; // 1000 - 9999
    _aptNumberController.text = 'APT-$randomDigits';
  }

  @override
  void dispose() {
    _aptNumberController.dispose();
    _notesController.dispose();
    _stateCubit.close();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue1,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _stateCubit.update(_stateCubit.state.copyWith(selectedDate: picked));
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue1,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _stateCubit.update(_stateCubit.state.copyWith(selectedTime: picked));
    }
  }

  void _submitAppointment() {
    if (_formKey.currentState?.validate() ?? false) {
      final currentState = _stateCubit.state;
      if (currentState.selectedDate == null) {
        AppSnackBar.showWarning(context, 'Please select an appointment date');
        return;
      }
      if (currentState.selectedTime == null) {
        AppSnackBar.showWarning(context, 'Please select an appointment time');
        return;
      }

      final formattedTime = '${currentState.selectedTime!.hour.toString().padLeft(2, '0')}:${currentState.selectedTime!.minute.toString().padLeft(2, '0')}';
      
      final appointment = AppointmentModel(
        id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
        requestId: widget.requestId,
        appointmentNumber: _aptNumberController.text.trim(),
        date: currentState.selectedDate!,
        time: formattedTime,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      context.read<AppointmentBloc>().add(AssignAppointment(appointment));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state.status == AppointmentStatus.assigned && state.appointment != null) {
          // Success toast
          AppSnackBar.showSuccess(
            context,
            AppStrings.appointmentConfirmedToast.replaceAll('{id}', state.appointment!.appointmentNumber),
          );
          widget.onConfirmed(state.appointment!);
        } else if (state.status == AppointmentStatus.failure) {
          AppSnackBar.showError(context, state.errorMessage ?? 'Failed to assign appointment');
        }
      },
      builder: (context, state) {
        final bool isLoading = state.status == AppointmentStatus.loading;

        return BlocBuilder<ValueCubit<AssignAppointmentState>, AssignAppointmentState>(
          bloc: _stateCubit,
          builder: (context, appointmentState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.blue3,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Handle Bar
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Assign Appointment',
                        style: TextStyles.headingSemiBold.copyWith(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Appointment Number field
                      Text(
                        'Appointment Number',
                        style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _aptNumberController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'e.g. APT-1001',
                        ),
                        validator: (v) => Validators.validateRequired(v, 'Appointment number'),
                      ),
                      const SizedBox(height: 20),

                      // Date and Time Pickers Row
                      Row(
                        children: [
                          // Date Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      border: Border.all(color: AppColors.blue2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, color: AppColors.blue1, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            appointmentState.selectedDate == null
                                                ? 'Select Date'
                                                : '${appointmentState.selectedDate!.day}/${appointmentState.selectedDate!.month}/${appointmentState.selectedDate!.year}',
                                            style: TextStyle(
                                              color: appointmentState.selectedDate == null ? AppColors.textMuted : Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Time Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectTime,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      border: Border.all(color: AppColors.blue2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, color: AppColors.blue1, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            appointmentState.selectedTime == null
                                                ? 'Select Time'
                                                : appointmentState.selectedTime!.format(context),
                                            style: TextStyle(
                                              color: appointmentState.selectedTime == null ? AppColors.textMuted : Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Optional Notes
                      Text(
                        'Notes / Instructions (Optional)',
                        style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter fasting requirements, prepare documents, etc.',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // CTA Gradient Confirm button
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [AppColors.blue1, AppColors.blue2],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Confirm Appointment',
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
      },
    );
  }
}
