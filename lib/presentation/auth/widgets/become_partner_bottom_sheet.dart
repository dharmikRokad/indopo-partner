import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presentation/widgets/address_autocomplete_field.dart';
import '../../../core/presentation/widgets/app_snackbar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/partner_type.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class BecomePartnerBottomSheet extends StatefulWidget {
  final PartnerType? initialRole;

  const BecomePartnerBottomSheet({super.key, this.initialRole});

  static Future<void> show(BuildContext context, {PartnerType? initialRole}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BecomePartnerBottomSheet(initialRole: initialRole);
      },
    );
  }

  @override
  State<BecomePartnerBottomSheet> createState() =>
      _BecomePartnerBottomSheetState();
}

class _BecomePartnerBottomSheetState extends State<BecomePartnerBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late PartnerType? _selectedRole;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgAddressController = TextEditingController();

  double? _selectedLat;
  double? _selectedLong;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? PartnerType.doctor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgNameController.dispose();
    _orgAddressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedRole == null) {
      AppSnackBar.showError(context, 'Please select a partner type.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_orgAddressController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please enter organization address.');
      return;
    }

    context.read<AuthBloc>().add(
      BecomePartnerSubmitted(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        orgName: _orgNameController.text.trim(),
        orgAddress: _orgAddressController.text.trim(),
        partnerType: _selectedRole!,
        lat: _selectedLat,
        long: _selectedLong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthBlocStatus.becomePartnerSuccess) {
          Navigator.of(context).pop();
          AppSnackBar.showSuccess(
            context,
            state.successMessage ??
                'Your request to become a partner has been submitted successfully.',
          );
        } else if (state.status == AuthBlocStatus.becomePartnerFailure) {
          AppSnackBar.showError(
            context,
            state.errorMessage ?? 'Failed to submit request.',
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.blue3,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.blue2, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Become a Partner',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.blue2, height: 1),

              // Form Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Partner Type',
                          style: TextStyles.headingSemiBold.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SheetRoleCard(
                                label: AppStrings.doctor,
                                icon: '🩺',
                                isSelected: _selectedRole == PartnerType.doctor,
                                onTap: () => setState(
                                  () => _selectedRole = PartnerType.doctor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SheetRoleCard(
                                label: AppStrings.medical,
                                icon: '💊',
                                isSelected:
                                    _selectedRole == PartnerType.pharmacy,
                                onTap: () => setState(
                                  () => _selectedRole = PartnerType.pharmacy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SheetRoleCard(
                                label: AppStrings.laboratory,
                                icon: '🧪',
                                isSelected:
                                    _selectedRole == PartnerType.laboratory,
                                onTap: () => setState(
                                  () => _selectedRole = PartnerType.laboratory,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SheetRoleCard(
                                label: AppStrings.imagingCenter,
                                icon: '🏥',
                                isSelected:
                                    _selectedRole == PartnerType.imagingCenter,
                                onTap: () => setState(
                                  () =>
                                      _selectedRole = PartnerType.imagingCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Full Name
                        Text(
                          'Full Name',
                          style: TextStyles.headingSemiBold.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppColors.textMuted,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Address
                        Text(
                          'Email Address',
                          style: TextStyles.headingSemiBold.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        Text(
                          'Phone Number',
                          style: TextStyles.headingSemiBold.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter contact phone number',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Organization Name
                        Text(
                          'Organization Name',
                          style: TextStyles.headingSemiBold.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _orgNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter clinic, hospital, or shop name',
                            prefixIcon: Icon(
                              Icons.business_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter organization name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Organization Address Autocomplete Field
                        AddressAutocompleteField(
                          controller: _orgAddressController,
                          label: 'Organization Address',
                          hint: 'Search organization address',
                          initialLat: _selectedLat,
                          initialLong: _selectedLong,
                          onLocationChanged: (address, lat, long) {
                            _selectedLat = lat;
                            _selectedLong = long;
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter organization address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading =
                                state.status ==
                                AuthBlocStatus.becomePartnerLoading;
                            return Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [AppColors.blue1, AppColors.blue2],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
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
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Submit Request',
                                        style: TextStyles.headingBold.copyWith(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetRoleCard extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetRoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        height: 80,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.blue1, AppColors.blue2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.blue3,
          border: Border.all(
            color: isSelected ? AppColors.blue1 : AppColors.blue2,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Colors.white,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
