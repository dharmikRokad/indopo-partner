import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/presentation/widgets/address_autocomplete_field.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/repositories/profile_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class ProfileScreenState {
  final bool isEditing;
  final bool isLoading;
  final List<String> selectedModalities;
  final List<String> selectedDays;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final double? lat;
  final double? long;

  const ProfileScreenState({
    this.isEditing = false,
    this.isLoading = false,
    this.selectedModalities = const [],
    this.selectedDays = const [],
    this.openTime,
    this.closeTime,
    this.lat,
    this.long,
  });

  ProfileScreenState copyWith({
    bool? isEditing,
    bool? isLoading,
    List<String>? selectedModalities,
    List<String>? selectedDays,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    double? lat,
    double? long,
  }) {
    return ProfileScreenState(
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      selectedModalities: selectedModalities ?? this.selectedModalities,
      selectedDays: selectedDays ?? this.selectedDays,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
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
  final _stateCubit = ValueCubit<ProfileScreenState>(const ProfileScreenState());
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
  
  // Imaging center modalities tracker
  final List<String> _allModalities = [
    'CT Scan',
    'MRI',
    'X-Ray',
    'Ultrasound',
    'PET Scan',
    'Mammography',
  ];

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
    _nameController.text = partner.details['full_name'] ?? 
                           partner.details['lab_name'] ?? 
                           partner.details['center_name'] ?? '';
    _specializationController.text = partner.details['specialization'] ?? '';
    _regNumController.text = partner.details['reg_number'] ?? 
                             partner.details['accreditation_number'] ?? '';
    _clinicNameController.text = partner.details['clinic_name'] ?? 
                                 partner.details['clinic_hospital_name'] ?? '';
    _contactPersonController.text = partner.details['contact_person'] ?? '';
    _addressController.text = partner.orgAddress ?? partner.details['address'] ?? '';
    _phoneController.text = partner.details['phone'] ?? '';
    _consultationFeeController.text = (partner.details['consultation_fee'] ?? 0.0).toString();

    final selectedModalities = <String>[];
    final dynamic modalities = partner.details['modalities'];
    if (modalities is List) {
      selectedModalities.addAll(modalities.map((e) => e.toString()));
    }

    final selectedDays = <String>[];
    if (partner.workingDays != null) {
      selectedDays.addAll(partner.workingDays!);
    }
    final openTime = _parseTimeString(partner.openTime);
    final closeTime = _parseTimeString(partner.closeTime);

    _stateCubit.update(ProfileScreenState(
      isEditing: isEditing,
      isLoading: _stateCubit.state.isLoading,
      selectedModalities: selectedModalities,
      selectedDays: selectedDays,
      openTime: openTime,
      closeTime: closeTime,
      lat: partner.lat,
      long: partner.long,
    ));
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

  Future<void> _saveProfile(PartnerModel partner) async {
    if (!_formKey.currentState!.validate()) return;

    final currentState = _stateCubit.state;
    if (partner.role == PartnerType.imagingCenter && currentState.selectedModalities.isEmpty) {
      AppSnackBar.showWarning(context, 'Please select at least one modality');
      return;
    }

    if (currentState.selectedDays.isEmpty) {
      AppSnackBar.showWarning(context, 'Please select at least one working day');
      return;
    }
    if (currentState.openTime == null || currentState.closeTime == null) {
      AppSnackBar.showWarning(context, 'Please select opening and closing times');
      return;
    }
    if (currentState.openTime!.hour + currentState.openTime!.minute/60.0 >= currentState.closeTime!.hour + currentState.closeTime!.minute/60.0) {
      AppSnackBar.showWarning(context, 'Opening time must be earlier than closing time');
      return;
    }

    _stateCubit.update(_stateCubit.state.copyWith(isLoading: true));

    try {
      final details = <String, dynamic>{
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'visual_profile': partner.details['visual_profile'] ?? 'Simulated_Image_Path.jpg',
      };

      switch (partner.role) {
        case PartnerType.doctor:
          details['full_name'] = _nameController.text.trim();
          details['specialization'] = _specializationController.text.trim();
          details['reg_number'] = _regNumController.text.trim();
          details['clinic_name'] = _clinicNameController.text.trim();
          details['consultation_fee'] = double.tryParse(_consultationFeeController.text.trim()) ?? 0.0;
          break;
        case PartnerType.medical:
          details['full_name'] = _nameController.text.trim();
          details['reg_number'] = _regNumController.text.trim();
          details['clinic_hospital_name'] = _clinicNameController.text.trim();
          break;
        case PartnerType.laboratory:
          details['lab_name'] = _nameController.text.trim();
          details['accreditation_number'] = _regNumController.text.trim();
          details['contact_person'] = _contactPersonController.text.trim();
          break;
        case PartnerType.imagingCenter:
          details['center_name'] = _nameController.text.trim();
          details['accreditation_number'] = _regNumController.text.trim();
          details['modalities'] = currentState.selectedModalities;
          break;
      }

      final updatedPartner = partner.copyWith(
        details: details,
        isProfileConfigured: true,
        workingDays: currentState.selectedDays,
        openTime: _formatTimeOfDay(currentState.openTime!),
        closeTime: _formatTimeOfDay(currentState.closeTime!),
        lat: currentState.lat,
        long: currentState.long,
        orgAddress: _addressController.text.trim(),
      );

      final savedPartner = await context.read<ProfileRepository>().saveProfile(updatedPartner);
      
      // Update global AuthBloc
      context.read<AuthBloc>().add(PartnerUpdated(savedPartner));

      AppSnackBar.showSuccess(context, 'Profile updated successfully!');

      _stateCubit.update(_stateCubit.state.copyWith(isEditing: false));
    } catch (e) {
      AppSnackBar.showError(context, 'Failed to update profile: $e');
    } finally {
      _stateCubit.update(_stateCubit.state.copyWith(isLoading: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final partner = authState.partner;

    final displayName = partner.details['full_name'] ?? 
                        partner.details['lab_name'] ?? 
                        partner.details['center_name'] ?? 
                        'Provider';
                        
    final initials = displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return BlocBuilder<ValueCubit<ProfileScreenState>, ProfileScreenState>(
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
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.blue2.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.blue2,
                          child: Text(
                            initials.isEmpty ? 'P' : initials,
                            style: TextStyles.headingBold.copyWith(fontSize: 28),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: TextStyles.headingBold.copyWith(fontSize: 22),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          partner.email,
                          style: TextStyles.labelRegular.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.blue2.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.blue1, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(partner.role.icon, style: const TextStyle(fontSize: 16)),
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
                                          : () => _stateCubit.update(state.copyWith(isEditing: false)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.textMuted),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('Cancel', style: TextStyles.headingSemiBold.copyWith(color: AppColors.textMuted)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: const LinearGradient(
                                          colors: [AppColors.blue1, AppColors.blue2],
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: state.isLoading ? null : () => _saveProfile(partner),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: state.isLoading 
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : Text('Save Changes', style: TextStyles.headingBold.copyWith(fontSize: 16)),
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
                          children: [
                            _buildViewFields(partner),
                            const SizedBox(height: 28),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [AppColors.blue1, AppColors.blue2],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _initFormFields(partner, isEditing: true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'Edit Profile',
                                  style: TextStyles.headingBold.copyWith(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        );
      },
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
                _buildInfoRow('Specialization', partner.details['specialization'] ?? 'Not specified'),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow('Reg Number', partner.details['reg_number'] ?? 'Not specified'),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow('Clinic Name', partner.details['clinic_name'] ?? 'Not specified'),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow('Consultation Fee', '\$${partner.details['consultation_fee'] ?? 0.0}'),
              ] else if (partner.role == PartnerType.medical) ...[
                _buildInfoRow('License Number', partner.details['reg_number'] ?? 'Not specified'),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow('Practice Name', partner.details['clinic_hospital_name'] ?? 'Not specified'),
              ] else if (partner.role == PartnerType.laboratory) ...[
                _buildInfoRow('Accreditation', partner.details['accreditation_number'] ?? 'Not specified'),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow('Contact Person', partner.details['contact_person'] ?? 'Not specified'),
              ] else if (partner.role == PartnerType.imagingCenter) ...[
                _buildInfoRow('Accreditation', partner.details['accreditation_number'] ?? 'Not specified'),
                const Divider(color: AppColors.blue3, height: 24),
                _buildInfoRow(
                  'Modalities',
                  (partner.details['modalities'] as List?)?.join(', ') ?? 'Not specified',
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
              _buildInfoRow('Phone', partner.details['phone'] ?? 'Not specified'),
              const Divider(color: AppColors.blue3, height: 24),
              _buildInfoRow('Address', partner.details['address'] ?? 'Not specified'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Working Hours'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInfoRow('Working Days', partner.workingDays?.join(', ') ?? 'Not specified'),
              const Divider(color: AppColors.blue3, height: 24),
              _buildInfoRow('Open / Close Time', 
                partner.openTime != null && partner.closeTime != null
                    ? '${partner.openTime} - ${partner.closeTime}'
                    : 'Not specified'),
            ],
          ),
        ),
        if (partner.role == PartnerType.laboratory || partner.role == PartnerType.imagingCenter) ...[
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue2.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.layers_outlined, color: AppColors.blue1),
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
        
    final regLabel = (role == PartnerType.laboratory || role == PartnerType.imagingCenter) 
        ? 'Accreditation Number' 
        : (role == PartnerType.medical ? 'License / Registration Number' : 'Medical Registration Number');

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
            label: 'Consultation Fee (\$)',
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

        if (role == PartnerType.doctor || role == PartnerType.medical) ...[
          _buildTextField(
            controller: _clinicNameController,
            label: role == PartnerType.doctor ? 'Clinic Name' : 'Clinic / Hospital Name',
            hint: 'Enter practice name',
            validator: (v) => Validators.validateRequired(v, 'Practice name'),
          ),
          const SizedBox(height: 16),
        ],

        if (role == PartnerType.laboratory) ...[
          _buildTextField(
            controller: _contactPersonController,
            label: 'Contact Person Name',
            hint: 'Enter contact name',
            validator: (v) => Validators.validateRequired(v, 'Contact person'),
          ),
          const SizedBox(height: 16),
        ],

        if (role == PartnerType.imagingCenter) ...[
          Text('Modalities Provided', style: TextStyles.headingSemiBold.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allModalities.map((modality) {
              final isSelected = state.selectedModalities.contains(modality);
              return FilterChip(
                label: Text(modality),
                selected: isSelected,
                selectedColor: AppColors.blue2,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.blue1 : AppColors.blue2.withValues(alpha: 0.5),
                  ),
                ),
                onSelected: (selected) {
                  final list = List<String>.from(state.selectedModalities);
                  if (selected) {
                    list.add(modality);
                  } else {
                    list.remove(modality);
                  }
                  _stateCubit.update(state.copyWith(selectedModalities: list));
                },
              );
            }).toList(),
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
            _stateCubit.update(_stateCubit.state.copyWith(
              lat: lat,
              long: long,
            ));
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
        
        Text('Working Days', style: TextStyles.headingSemiBold.copyWith(fontSize: 14, color: AppColors.blue1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((day) {
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
                  fontSize: 12,
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

        Text('Working Hours', style: TextStyles.headingSemiBold.copyWith(fontSize: 14, color: AppColors.blue1)),
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
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyles.headingSemiBold.copyWith(fontSize: 16, color: AppColors.blue1),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: enabled
                ? null
                : const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
            helperText: enabled ? null : 'Contact support to change specialization',
            helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _selectTime({required bool isOpenTime}) async {
    final initialTime = isOpenTime
        ? (_stateCubit.state.openTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_stateCubit.state.closeTime ?? const TimeOfDay(hour: 18, minute: 0));

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
        _stateCubit.update(_stateCubit.state.copyWith(openTime: picked));
      } else {
        _stateCubit.update(_stateCubit.state.copyWith(closeTime: picked));
      }
    }
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
