import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../../data/repositories/profile_repo.dart';
import '../cubit/address_autocomplete_cubit.dart';
import 'app_snackbar.dart';

class AddressAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final double? initialLat;
  final double? initialLong;
  final Function(String address, double lat, double long) onLocationChanged;
  final FormFieldValidator<String>? validator;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.initialLat,
    this.initialLong,
    required this.onLocationChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddressAutocompleteCubit(),
      child: _AddressAutocompleteView(
        controller: controller,
        label: label,
        hint: hint,
        onLocationChanged: onLocationChanged,
        validator: validator,
      ),
    );
  }
}

class _AddressAutocompleteView extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Function(String address, double lat, double long) onLocationChanged;
  final FormFieldValidator<String>? validator;

  const _AddressAutocompleteView({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onLocationChanged,
    this.validator,
  });

  @override
  State<_AddressAutocompleteView> createState() => _AddressAutocompleteViewState();
}

class _AddressAutocompleteViewState extends State<_AddressAutocompleteView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          context.read<AddressAutocompleteCubit>().clearSuggestions();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileRepo = context.read<ProfileRepository>();

    return BlocConsumer<AddressAutocompleteCubit, AddressAutocompleteState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          AppSnackBar.showSuccess(context, state.successMessage!);
        }
        if (state.errorMessage != null) {
          AppSnackBar.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyles.headingSemiBold.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: null,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.blue2.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.blue2.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.blue1),
                ),
                suffixIcon: state.isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(14.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.blue1,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.blue1,
                        ),
                        tooltip: 'Get Current Location',
                        onPressed: () {
                          context.read<AddressAutocompleteCubit>().getCurrentLocation(
                                context,
                                profileRepo,
                                widget.controller,
                                widget.onLocationChanged,
                              );
                        },
                      ),
              ),
              validator: widget.validator,
              onChanged: (query) {
                context
                    .read<AddressAutocompleteCubit>()
                    .onTextChanged(query, profileRepo);
              },
            ),
            if (state.isLoadingSuggestions)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            if (state.suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.blue2.withValues(alpha: 0.3),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.suggestions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.blue3, height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = state.suggestions[index];
                    return ListTile(
                      title: Text(
                        suggestion['display_name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      onTap: () {
                        widget.controller.text =
                            suggestion['display_name'] ?? '';
                        widget.onLocationChanged(
                          suggestion['display_name'] ?? '',
                          suggestion['lat'] ?? 0.0,
                          suggestion['lon'] ?? 0.0,
                        );
                        context
                            .read<AddressAutocompleteCubit>()
                            .clearSuggestions();
                        _focusNode.unfocus();
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
