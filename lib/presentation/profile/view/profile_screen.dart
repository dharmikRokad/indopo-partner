import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/presentation/widgets/address_autocomplete_field.dart';
import '../../../core/presentation/widgets/logout_confirmation_dialog.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/day_schedule_model.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/repositories/profile_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/presentation/bloc/value_cubit.dart';
import '../../../core/presentation/widgets/weekly_schedule_editor.dart';

class ProfileScreenState {
  final bool isEditing;
  final bool isLoading;
  final File? selectedImageFile;
  final List<String> selectedModalities;
  final Map<String, DaySchedule> weeklySchedule;
  final double? lat;
  final double? long;

  const ProfileScreenState({
    this.isEditing = false,
    this.isLoading = false,
    this.selectedImageFile,
    this.selectedModalities = const [],
    this.weeklySchedule = const {},
    this.lat,
    this.long,
  });

  ProfileScreenState copyWith({
    bool? isEditing,
    bool? isLoading,
    File? selectedImageFile,
    List<String>? selectedModalities,
    Map<String, DaySchedule>? weeklySchedule,
    double? lat,
    double? long,
  }) {
    return ProfileScreenState(
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      selectedImageFile: selectedImageFile ?? this.selectedImageFile,
      selectedModalities: selectedModalities ?? this.selectedModalities,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      lat: lat ?? this.lat,
      long: long ?? this.long,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _stateCubit = ValueCubit<ProfileScreenState>(
    const ProfileScreenState(),
  );
  final _formKey = GlobalKey<FormState>();

  // Text controllers for the edit form
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _regNumController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _consultationFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthBlocStatus.authenticated &&
        authState.partner != null) {
      _initFormFields(authState.partner!, isEditing: false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _regNumController.dispose();
    _clinicNameController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _consultationFeeController.dispose();
    _stateCubit.close();
    super.dispose();
  }

  void _initFormFields(PartnerModel partner, {bool isEditing = false}) {
    _nameController.text =
        partner.details['full_name'] ??
        partner.details['lab_name'] ??
        partner.details['center_name'] ??
        '';
    _specializationController.text = partner.details['specialization'] ?? '';
    _regNumController.text =
        partner.details['reg_number'] ??
        partner.details['accreditation_number'] ??
        '';
    _clinicNameController.text =
        partner.details['org_name'] ??
        partner.details['clinic_name'] ??
        partner.details['clinic_hospital_name'] ??
        '';
    _contactPersonController.text = partner.details['contact_person'] ?? '';
    _addressController.text =
        partner.orgAddress ?? partner.details['address'] ?? '';
    _phoneController.text = partner.details['phone'] ?? '';
    _consultationFeeController.text =
        (partner.details['consultation_fee'] ?? 0.0).toString();

    final selectedModalities = <String>[];
    final dynamic modalities = partner.details['modalities'];
    if (modalities is List) {
      selectedModalities.addAll(modalities.map((e) => e.toString()));
    }

    Map<String, DaySchedule> schedule = {};
    if (partner.weeklySchedule != null && partner.weeklySchedule!.isNotEmpty) {
      schedule = Map<String, DaySchedule>.from(partner.weeklySchedule!);
    } else {
      for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
        schedule[day] = const DaySchedule(open: '09:00', close: '17:00');
      }
    }

    _stateCubit.update(
      ProfileScreenState(
        isEditing: isEditing,
        isLoading: _stateCubit.state.isLoading,
        selectedModalities: selectedModalities,
        weeklySchedule: schedule,
        lat: partner.lat,
        long: partner.long,
      ),
    );
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

  Future<void> _pickProfileImage(
    PartnerModel partner,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final file = File(picked.path);
        _stateCubit.update(_stateCubit.state.copyWith(selectedImageFile: file));

        if (!_stateCubit.state.isEditing) {
          await _uploadProfilePicture(partner, file);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to select image: $e');
      }
    }
  }

  Future<void> _uploadProfilePicture(PartnerModel partner, File file) async {
    _stateCubit.update(_stateCubit.state.copyWith(isLoading: true));
    try {
      final savedPartner = await context.read<ProfileRepository>().saveProfile(
        partner,
        profilePictureFile: file,
      );
      if (!mounted) return;
      context.read<AuthBloc>().add(PartnerUpdated(savedPartner));
      AppSnackBar.showSuccess(context, 'Profile picture updated successfully!');
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to update profile picture: $e');
      }
    } finally {
      _stateCubit.update(_stateCubit.state.copyWith(isLoading: false));
    }
  }

  void _showImagePickerModal(BuildContext context, PartnerModel partner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.blue3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Profile Picture',
                  style: TextStyles.headingSemiBold.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.blue1,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyles.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(partner, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.blue1,
                  ),
                  title: Text('Take a Photo', style: TextStyles.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(partner, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile(PartnerModel partner) async {
    if (!_formKey.currentState!.validate()) return;

    final currentState = _stateCubit.state;

    final validationError = _validateSchedule(currentState.weeklySchedule);
    if (validationError != null) {
      AppSnackBar.showWarning(context, validationError);
      return;
    }

    _stateCubit.update(_stateCubit.state.copyWith(isLoading: true));

    try {
      final details = <String, dynamic>{
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'visual_profile':
            partner.details['visual_profile'] ?? 'Simulated_Image_Path.jpg',
      };

      switch (partner.role) {
        case PartnerType.doctor:
          details['full_name'] = _nameController.text.trim();
          details['specialization'] = _specializationController.text.trim();
          details['reg_number'] = _regNumController.text.trim();
          details['clinic_name'] = _clinicNameController.text.trim();
          details['org_name'] = _clinicNameController.text.trim();
          details['consultation_fee'] =
              double.tryParse(_consultationFeeController.text.trim()) ?? 0.0;
          break;
        case PartnerType.pharmacy:
          details['full_name'] = _nameController.text.trim();
          details['reg_number'] = _regNumController.text.trim();
          details['clinic_hospital_name'] = _clinicNameController.text.trim();
          details['org_name'] = _clinicNameController.text.trim();
          break;
        case PartnerType.laboratory:
          details['lab_name'] = _nameController.text.trim();
          details['accreditation_number'] = _regNumController.text.trim();
          details['contact_person'] = _contactPersonController.text.trim();
          details['org_name'] = _clinicNameController.text.trim();
          break;
        case PartnerType.imagingCenter:
          details['center_name'] = _nameController.text.trim();
          details['accreditation_number'] = _regNumController.text.trim();
          details['modalities'] = partner.details['modalities'];
          details['org_name'] = _clinicNameController.text.trim();
          break;
      }

      final updatedPartner = partner.copyWith(
        details: details,
        isProfileConfigured: true,
        weeklySchedule: currentState.weeklySchedule,
        lat: currentState.lat,
        long: currentState.long,
        orgAddress: _addressController.text.trim(),
      );

      final savedPartner = await context.read<ProfileRepository>().saveProfile(
        updatedPartner,
        profilePictureFile: currentState.selectedImageFile,
      );
      if (!mounted) return;

      // Update global AuthBloc
      context.read<AuthBloc>().add(PartnerUpdated(savedPartner));

      AppSnackBar.showSuccess(context, 'Profile updated successfully!');

      _stateCubit.update(_stateCubit.state.copyWith(isEditing: false));
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to update profile: $e');
      }
    } finally {
      _stateCubit.update(_stateCubit.state.copyWith(isLoading: false));
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

    final displayName =
        partner.details['full_name'] ??
        partner.details['lab_name'] ??
        partner.details['center_name'] ??
        'Provider';

    final initials = displayName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthBlocStatus.authenticated &&
            authState.partner != null &&
            !_stateCubit.state.isEditing) {
          _initFormFields(authState.partner!, isEditing: false);
        }
      },
      child: BlocBuilder<ValueCubit<ProfileScreenState>, ProfileScreenState>(
        bloc: _stateCubit,
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.blue3,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                state.isEditing ? 'Edit Profile' : 'Profile',
                style: TextStyles.headingSemiBold.copyWith(fontSize: 20),
              ),
              actions: [
                if (!state.isEditing)
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
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
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.blue2.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (!state.isEditing)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _initFormFields(partner, isEditing: true);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue2.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.blue1.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: AppColors.blue1,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showImagePickerModal(
                                        context,
                                        partner,
                                      ),
                                      child: CircleAvatar(
                                        radius: 44,
                                        backgroundColor: AppColors.blue2,
                                        backgroundImage:
                                            state.selectedImageFile != null
                                            ? FileImage(
                                                    state.selectedImageFile!,
                                                  )
                                                  as ImageProvider
                                            : (partner.profilePicture != null &&
                                                      partner
                                                          .profilePicture!
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      partner.profilePicture!,
                                                    )
                                                  : null),
                                        child:
                                            (state.selectedImageFile == null &&
                                                (partner.profilePicture ==
                                                        null ||
                                                    partner
                                                        .profilePicture!
                                                        .isEmpty))
                                            ? Text(
                                                initials.isEmpty
                                                    ? 'P'
                                                    : initials,
                                                style: TextStyles.headingBold
                                                    .copyWith(fontSize: 28),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _showImagePickerModal(
                                          context,
                                          partner,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.blue1,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  displayName,
                                  style: TextStyles.headingBold.copyWith(
                                    fontSize: 22,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  partner.email,
                                  style: TextStyles.labelRegular.copyWith(
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue2.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.blue1,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        partner.role.icon,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        partner.role.displayName,
                                        style: TextStyles.bodyMedium.copyWith(
                                          color: AppColors.blue1,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content based on Mode
                    state.isEditing
                        ? Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildEditFields(partner.role, state),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: state.isLoading
                                            ? null
                                            : () => _stateCubit.update(
                                                state.copyWith(
                                                  isEditing: false,
                                                ),
                                              ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppColors.textMuted,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyles.headingSemiBold
                                              .copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppColors.blue1,
                                              AppColors.blue2,
                                            ],
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: state.isLoading
                                              ? null
                                              : () => _saveProfile(partner),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: state.isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  'Save',
                                                  style: TextStyles.headingBold
                                                      .copyWith(fontSize: 16),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [_buildViewFields(partner)],
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // View mode detail items renderer
  Widget _buildViewFields(PartnerModel partner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Provider Details'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (partner.role == PartnerType.doctor) ...[
                _buildInfoRow(
                  'Specialization',
                  partner.details['specialization'] ?? 'Not specified',
                ),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Reg Number',
                  partner.details['reg_number'] ?? 'Not specified',
                ),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Clinic Name',
                  partner.details['org_name'] ??
                      partner.details['clinic_name'] ??
                      'Not specified',
                ),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Consultation Fee',
                  '₹${partner.details['consultation_fee'] ?? 0.0}',
                ),
              ] else if (partner.role == PartnerType.pharmacy) ...[
                _buildInfoRow(
                  'License Number',
                  partner.details['reg_number'] ?? 'Not specified',
                ),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Practice Name',
                  partner.details['org_name'] ??
                      partner.details['clinic_hospital_name'] ??
                      'Not specified',
                ),
              ] else if (partner.role == PartnerType.laboratory) ...[
                _buildInfoRow(
                  'Accreditation',
                  partner.details['accreditation_number'] ?? 'Not specified',
                ),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Organization Name',
                  partner.details['org_name'] ?? 'Not specified',
                ),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Contact Person',
                  partner.details['contact_person'] ?? 'Not specified',
                ),
              ] else if (partner.role == PartnerType.imagingCenter) ...[
                _buildInfoRow(
                  'Accreditation',
                  partner.details['accreditation_number'] ?? 'Not specified',
                ),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Organization Name',
                  partner.details['org_name'] ?? 'Not specified',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('Contact Details'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                'Phone',
                partner.details['phone'] ?? 'Not specified',
              ),
              const Divider(color: AppColors.blue3, height: 24),
              _buildInfoRow(
                'Address',
                partner.details['address'] ?? 'Not specified',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Working Hours'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: kDaysOfWeek.map((day) {
              final schedule = partner.weeklySchedule?[day];
              final isLast = day == kDaysOfWeek.last;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: schedule != null
                                    ? AppColors.blue1
                                    : AppColors.textMuted.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              day,
                              style: TextStyles.labelRegular.copyWith(
                                fontSize: 14,
                                color: schedule != null
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: schedule != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        if (schedule != null)
                          Text(
                            schedule.toString(),
                            style: TextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              color: AppColors.blue1,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue3,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Closed',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(color: AppColors.blue3, height: 10),
                ],
              );
            }).toList(),
          ),
        ),
        if (partner.role == PartnerType.laboratory ||
            partner.role == PartnerType.imagingCenter) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Services'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue2.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue2.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: AppColors.blue1,
                ),
              ),
              title: Text(
                'Manage Services',
                style: TextStyles.headingSemiBold.copyWith(fontSize: 16),
              ),
              subtitle: Text(
                'Add, edit, delete or toggle service availability',
                style: TextStyles.labelRegular.copyWith(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () {
                context.push(AppRoutes.services);
              },
            ),
          ),
        ],
      ],
    );
  }

  // Edit mode fields builder
  Widget _buildEditFields(PartnerType role, ProfileScreenState state) {
    final nameLabel = (role == PartnerType.laboratory)
        ? 'Laboratory Name'
        : (role == PartnerType.imagingCenter ? 'Center Name' : 'Full Name');

    final regLabel =
        (role == PartnerType.laboratory || role == PartnerType.imagingCenter)
        ? 'Accreditation Number'
        : (role == PartnerType.pharmacy
              ? 'License / Registration Number'
              : 'Medical Registration Number');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Edit Details'),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _nameController,
          label: nameLabel,
          hint: 'Enter name',
          validator: (v) => Validators.validateRequired(v, nameLabel),
        ),
        const SizedBox(height: 16),

        if (role == PartnerType.doctor) ...[
          _buildTextField(
            controller: _specializationController,
            label: 'Specialization',
            hint: 'Cardiology, Pediatrics, etc.',
            enabled: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _consultationFeeController,
            label: 'Consultation Fee (₹)',
            hint: 'Enter consultation fee',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Consultation fee is required';
              }
              if (double.tryParse(v) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        _buildTextField(
          controller: _regNumController,
          label: regLabel,
          hint: 'Enter register or license number',
          validator: (v) => Validators.validateRequired(v, regLabel),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _clinicNameController,
          label: role.orgNameTitle,
          hint: 'Enter organization/clinic name',
          validator: (v) => Validators.validateRequired(
            v,
            role == PartnerType.doctor
                ? 'Clinic name'
                : (role == PartnerType.pharmacy
                      ? 'Practice name'
                      : 'Organization name'),
          ),
        ),
        const SizedBox(height: 16),

        if (role == PartnerType.laboratory) ...[
          _buildTextField(
            controller: _contactPersonController,
            label: 'Contact Person Name',
            hint: 'Enter contact name',
            validator: (v) => Validators.validateRequired(v, 'Contact person'),
          ),
          const SizedBox(height: 16),
        ],

        AddressAutocompleteField(
          controller: _addressController,
          label: 'Physical Address',
          hint: '123 Medical Street, Suite 4',
          initialLat: state.lat,
          initialLong: state.long,
          onLocationChanged: (address, lat, long) {
            _stateCubit.update(
              _stateCubit.state.copyWith(lat: lat, long: long),
            );
          },
          validator: (v) => Validators.validateRequired(v, 'Physical address'),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _phoneController,
          label: 'Contact Phone Number',
          hint: '+15551234567',
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
        ),
        const SizedBox(height: 24),

        WeeklyScheduleEditor(
          initialSchedule: state.weeklySchedule,
          onScheduleChanged: (updated) {
            _stateCubit.update(state.copyWith(weeklySchedule: updated));
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyles.headingSemiBold.copyWith(
        fontSize: 16,
        color: AppColors.blue1,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyles.labelRegular.copyWith(fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.bodyMedium.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.headingSemiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: enabled
                ? null
                : const Icon(
                    Icons.lock_outline,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
            helperText: enabled
                ? null
                : 'Contact support to change specialization',
            helperStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
