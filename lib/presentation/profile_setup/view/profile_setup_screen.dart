import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/partner_type.dart';
import '../../../data/repositories/profile_repo.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/profile_setup_bloc.dart';
import '../bloc/profile_setup_event.dart';
import '../bloc/profile_setup_state.dart';
import '../../../core/presentation/bloc/value_cubit.dart';

class ProfileSetupScreenState {
  final String uploadedPhotoPath;
  final List<String> selectedModalities;

  const ProfileSetupScreenState({
    this.uploadedPhotoPath = 'Simulated_Image_Path.jpg',
    this.selectedModalities = const [],
  });

  ProfileSetupScreenState copyWith({
    String? uploadedPhotoPath,
    List<String>? selectedModalities,
  }) {
    return ProfileSetupScreenState(
      uploadedPhotoPath: uploadedPhotoPath ?? this.uploadedPhotoPath,
      selectedModalities: selectedModalities ?? this.selectedModalities,
    );
  }
}

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtain active partner info from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final partner = authState.partner;

    return BlocProvider(
      create: (context) => ProfileSetupBloc(
        profileRepository: context.read<ProfileRepository>(),
        currentPartner: partner,
      ),
      child: _ProfileSetupContent(partner: partner),
    );
  }
}

class _ProfileSetupContent extends StatefulWidget {
  final PartnerModel partner;
  const _ProfileSetupContent({required this.partner});

  @override
  State<_ProfileSetupContent> createState() => _ProfileSetupContentState();
}

class _ProfileSetupContentState extends State<_ProfileSetupContent> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  // Form Field Controllers
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _regNumController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _contactPersonController = TextEditingController();

  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateCubit = ValueCubit<ProfileSetupScreenState>(
    const ProfileSetupScreenState(),
  );

  // Modalities for Imaging Center
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
    _stateCubit.close();
    super.dispose();
  }

  void _submitProfile() {
    if (_step2FormKey.currentState?.validate() ?? false) {
      final details = <String, dynamic>{
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'visual_profile': _stateCubit.state.uploadedPhotoPath,
      };

      switch (widget.partner.role) {
        case PartnerType.doctor:
          details['full_name'] = _nameController.text.trim();
          details['specialization'] = _specializationController.text.trim();
          details['reg_number'] = _regNumController.text.trim();
          details['clinic_name'] = _clinicNameController.text.trim();
          break;
        case PartnerType.pharmacy:
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
          details['modalities'] = _stateCubit.state.selectedModalities;
          break;
      }

      context.read<ProfileSetupBloc>().add(ProfileSubmitted(details));
    }
  }

  void _nextStep() {
    if (_step1FormKey.currentState?.validate() ?? false) {
      if (widget.partner.role == PartnerType.imagingCenter &&
          _stateCubit.state.selectedModalities.isEmpty) {
        AppSnackBar.showWarning(context, 'Please select at least one modality');
        return;
      }
      context.read<ProfileSetupBloc>().add(const ProfileStepChanged(1));
    }
  }

  void _prevStep() {
    context.read<ProfileSetupBloc>().add(const ProfileStepChanged(0));
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.partner.role;

    return Scaffold(
      backgroundColor: AppColors.blue3,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile Setup', style: TextStyles.headingSemiBold),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileSetupBloc, ProfileSetupState>(
        listener: (context, state) {
          if (state is ProfileSetupSuccess) {
            AppSnackBar.showSuccess(
              context,
              'Profile setup completed successfully!',
            );
            // Update auth state directly to trigger redirect to Dashboard
            context.read<AuthBloc>().add(PartnerUpdated(state.partner));
          } else if (state is ProfileSetupFailure) {
            AppSnackBar.showError(
              context,
              'Failed to setup profile: ${state.message}',
            );
          }
        },
        builder: (context, blocState) {
          int currentStep = 0;
          bool isLoading = false;

          if (blocState is ProfileStepState) {
            currentStep = blocState.step;
          } else if (blocState is ProfileSetupLoading) {
            currentStep = blocState.step;
            isLoading = true;
          } else if (blocState is ProfileSetupFailure) {
            currentStep = blocState.step;
          }

          return BlocBuilder<
            ValueCubit<ProfileSetupScreenState>,
            ProfileSetupScreenState
          >(
            bloc: _stateCubit,
            builder: (context, screenState) {
              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Role Badge & Info
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Step ${currentStep + 1} of 2',
                            style: TextStyles.labelRegular,
                          ),
                          // Styled Non-editable Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue2.withValues(alpha: 0.3),
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
                                  role.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  role.displayName,
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
                    const SizedBox(height: 8),

                    // Step progress bar (blue1 indicator)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (currentStep + 1) / 2,
                          minHeight: 6,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.blue1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: currentStep == 0
                            ? Form(
                                key: _step1FormKey,
                                child: _buildStep1Fields(role, screenState),
                              )
                            : Form(
                                key: _step2FormKey,
                                child: _buildStep2Fields(role, screenState),
                              ),
                      ),
                    ),

                    // Bottom navigation CTAs
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          if (currentStep > 0) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : _prevStep,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.blue1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Back',
                                  style: TextStyles.headingSemiBold.copyWith(
                                    color: AppColors.blue1,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
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
                                onPressed: isLoading
                                    ? null
                                    : (currentStep == 0
                                          ? _nextStep
                                          : _submitProfile),
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
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        currentStep == 0
                                            ? 'Next'
                                            : 'Submit & Finish',
                                        style: TextStyles.headingBold.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStep1Fields(PartnerType role, ProfileSetupScreenState state) {
    switch (role) {
      case PartnerType.doctor:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Information',
              style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Dr. Jane Doe',
              validator: (v) => Validators.validateRequired(v, 'Full name'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _specializationController,
              label: 'Specialization',
              hint: 'e.g., Cardiology',
              validator: (v) =>
                  Validators.validateRequired(v, 'Specialization'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _regNumController,
              label: 'Medical Registration Number',
              hint: 'MD-12345',
              validator: (v) =>
                  Validators.validateRequired(v, 'Registration number'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _clinicNameController,
              label: 'Clinic Name',
              hint: 'Heart Care Clinic',
              validator: (v) => Validators.validateRequired(v, 'Clinic name'),
            ),
          ],
        );
      case PartnerType.pharmacy:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Practice Information',
              style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Dr. John Smith',
              validator: (v) => Validators.validateRequired(v, 'Full name'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _regNumController,
              label: 'License / Registration Number',
              hint: 'LIC-67890',
              validator: (v) =>
                  Validators.validateRequired(v, 'License number'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _clinicNameController,
              label: 'Clinic / Hospital Name',
              hint: 'City Health Hospital',
              validator: (v) => Validators.validateRequired(v, 'Hospital name'),
            ),
          ],
        );
      case PartnerType.laboratory:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laboratory Information',
              style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Laboratory Name',
              hint: 'Apex Diagnostics Lab',
              validator: (v) =>
                  Validators.validateRequired(v, 'Laboratory name'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _regNumController,
              label: 'Accreditation Number',
              hint: 'LAB-ACC-1122',
              validator: (v) =>
                  Validators.validateRequired(v, 'Accreditation number'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _contactPersonController,
              label: 'Contact Person Name',
              hint: 'Jane Smith',
              validator: (v) =>
                  Validators.validateRequired(v, 'Contact person'),
            ),
          ],
        );
      case PartnerType.imagingCenter:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imaging Center Details',
              style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Center Name',
              hint: 'Precision Imaging Center',
              validator: (v) => Validators.validateRequired(v, 'Center name'),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _regNumController,
              label: 'Accreditation Number',
              hint: 'IMG-ACC-3344',
              validator: (v) =>
                  Validators.validateRequired(v, 'Accreditation number'),
            ),
            const SizedBox(height: 28),
            Text(
              'Modalities Provided',
              style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
            ),
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
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.blue1
                          : AppColors.blue2.withValues(alpha: 0.5),
                    ),
                  ),
                  onSelected: (selected) {
                    final list = List<String>.from(state.selectedModalities);
                    if (selected) {
                      list.add(modality);
                    } else {
                      list.remove(modality);
                    }
                    _stateCubit.update(
                      state.copyWith(selectedModalities: list),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        );
    }
  }

  Widget _buildStep2Fields(PartnerType role, ProfileSetupScreenState state) {
    final String photoLabel =
        (role == PartnerType.doctor || role == PartnerType.pharmacy)
        ? 'Profile Photo'
        : 'Company Logo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact & Visual Identity',
          style: TextStyles.headingSemiBold.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _addressController,
          label: 'Physical Address',
          hint: '123 Medical Blvd, Suite 400',
          maxLines: 2,
          validator: (v) => Validators.validateRequired(v, 'Physical address'),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Contact Phone Number',
          hint: '+15551234567',
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
        ),
        const SizedBox(height: 28),
        Text(
          photoLabel,
          style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        // Premium upload card design
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.blue2,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.blue3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.blue1),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.blue1,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload file',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG or PNG. Max size 2MB',
                      style: TextStyles.labelRegular.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Simulate image upload
                  _stateCubit.update(
                    state.copyWith(
                      uploadedPhotoPath:
                          'indopo_profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    ),
                  );
                  AppSnackBar.showInfo(
                    context,
                    '$photoLabel simulated upload complete!',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Browse'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Selected: ${state.uploadedPhotoPath}',
          style: TextStyles.labelRegular.copyWith(
            fontSize: 12,
            fontStyle: FontStyle.italic,
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }
}
