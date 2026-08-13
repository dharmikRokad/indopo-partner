import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/presentation/widgets/logout_confirmation_dialog.dart';
import '../../../core/presentation/widgets/weekly_schedule_editor.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/presentation/widgets/address_autocomplete_field.dart';
import '../../../data/models/day_schedule_model.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/profile_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class ScheduleSetupScreenState {
  final Map<String, DaySchedule> weeklySchedule;
  final String address;
  final double? lat;
  final double? long;
  final bool isLoading;

  const ScheduleSetupScreenState({
    this.weeklySchedule = const {},
    this.address = '',
    this.lat,
    this.long,
    this.isLoading = false,
  });

  ScheduleSetupScreenState copyWith({
    Map<String, DaySchedule>? weeklySchedule,
    String? address,
    double? lat,
    double? long,
    bool? isLoading,
  }) {
    return ScheduleSetupScreenState(
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
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
  final _stateCubit = ValueCubit<ScheduleSetupScreenState>(
    const ScheduleSetupScreenState(),
  );
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate if values exist
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthBlocStatus.authenticated &&
        authState.partner != null) {
      final partner = authState.partner!;
      final address = partner.details['address'] as String? ?? partner.orgAddress ?? '';
      _addressController.text = address;

      Map<String, DaySchedule> initialSchedule = {};
      if (partner.weeklySchedule != null && partner.weeklySchedule!.isNotEmpty) {
        initialSchedule = Map<String, DaySchedule>.from(partner.weeklySchedule!);
      } else {
        // Fallback default: Mon-Fri 09:00 - 17:00
        for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
          initialSchedule[day] = const DaySchedule(open: '09:00', close: '17:00');
        }
      }

      _stateCubit.update(
        ScheduleSetupScreenState(
          weeklySchedule: initialSchedule,
          address: address,
          lat: partner.lat,
          long: partner.long,
        ),
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _stateCubit.close();
    super.dispose();
  }

  String? _validateSchedule(Map<String, DaySchedule> schedule) {
    if (schedule.isEmpty) {
      return 'Please select at least one active working day';
    }

    double timeToMinutes(String timeStr) {
      final parts = timeStr.trim().split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return h * 60.0 + m;
    }

    for (final entry in schedule.entries) {
      final day = entry.key;
      final daySched = entry.value;

      final openMin = timeToMinutes(daySched.open);
      final closeMin = timeToMinutes(daySched.close);

      if (openMin >= closeMin) {
        return '$day: Open time (${daySched.open}) must be earlier than close time (${daySched.close})';
      }

      final hasBreakStart =
          daySched.breakStart != null && daySched.breakStart!.trim().isNotEmpty;
      final hasBreakEnd =
          daySched.breakEnd != null && daySched.breakEnd!.trim().isNotEmpty;

      if (hasBreakStart != hasBreakEnd) {
        return '$day: Both break start and break end must be provided';
      }

      if (hasBreakStart && hasBreakEnd) {
        final breakStartMin = timeToMinutes(daySched.breakStart!);
        final breakEndMin = timeToMinutes(daySched.breakEnd!);

        if (breakStartMin <= openMin) {
          return '$day: Break start (${daySched.breakStart}) must be after open time (${daySched.open})';
        }
        if (breakEndMin >= closeMin) {
          return '$day: Break end (${daySched.breakEnd}) must be before close time (${daySched.close})';
        }
        if (breakStartMin >= breakEndMin) {
          return '$day: Break start (${daySched.breakStart}) must be before break end (${daySched.breakEnd})';
        }
      }
    }
    return null;
  }

  Future<void> _submitSchedule(PartnerModel partner) async {
    final currentState = _stateCubit.state;
    // Validations
    if (currentState.address.trim().isEmpty) {
      AppSnackBar.showWarning(context, 'Please specify your physical address');
      return;
    }

    final validationError = _validateSchedule(currentState.weeklySchedule);
    if (validationError != null) {
      AppSnackBar.showWarning(context, validationError);
      return;
    }

    _stateCubit.update(currentState.copyWith(isLoading: true));

    try {
      final updatedDetails = Map<String, dynamic>.from(partner.details)
        ..['address'] = currentState.address.trim();

      final updatedPartner = partner.copyWith(
        weeklySchedule: currentState.weeklySchedule,
        details: updatedDetails,
        lat: currentState.lat,
        long: currentState.long,
        orgAddress: currentState.address.trim(),
      );

      final savedPartner = await context.read<ProfileRepository>().saveProfile(
        updatedPartner,
      );

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

    return BlocBuilder<
      ValueCubit<ScheduleSetupScreenState>,
      ScheduleSetupScreenState
    >(
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
                  final shouldLogout = await LogoutConfirmationDialog.show(
                    context,
                  );
                  if (shouldLogout == true && context.mounted) {
                    context.read<AuthBloc>().add(LogoutRequested());
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header description card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.blue2.withValues(alpha: 0.3),
                      ),
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
                          'Please specify the operating hours for each day your practice is open so patients can request appointments.',
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
                      _stateCubit.update(
                        _stateCubit.state.copyWith(
                          address: address,
                          lat: lat,
                          long: long,
                        ),
                      );
                    },
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Physical address is required'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Weekly Schedule Section
                  WeeklyScheduleEditor(
                    initialSchedule: state.weeklySchedule,
                    onScheduleChanged: (updatedSchedule) {
                      _stateCubit.update(
                        state.copyWith(weeklySchedule: updatedSchedule),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

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
                      onPressed: state.isLoading
                          ? null
                          : () => _submitSchedule(partner),
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
                              style: TextStyles.headingBold.copyWith(
                                fontSize: 16,
                              ),
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
}
