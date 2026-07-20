import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../services/location_service.dart';
import '../../../data/repositories/profile_repo.dart';
import 'app_snackbar.dart';

class AddressAutocompleteField extends StatefulWidget {
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
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isLoadingLocation = false;
  Timer? _debounce;
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
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Clear suggestions after a short delay to allow selection click to register
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _suggestions = [];
          });
        }
      });
    }
  }

  void _onTextChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (query.trim().length < 3) {
        setState(() {
          _suggestions = [];
        });
        return;
      }

      setState(() {
        _isLoadingSuggestions = true;
      });

      final repo = context.read<ProfileRepository>();
      final suggestions = await repo.getAddressSuggestions(query);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.instance.getCurrentLocation(context);
      if (position != null) {
        if (mounted) {
          final repo = context.read<ProfileRepository>();
          final address = await repo.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (mounted) {
            if (address != null) {
              widget.controller.text = address;
              widget.onLocationChanged(address, position.latitude, position.longitude);
              AppSnackBar.showSuccess(context, 'Location retrieved successfully!');
            } else {
              final fallbackAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
              widget.controller.text = fallbackAddress;
              widget.onLocationChanged(fallbackAddress, position.latitude, position.longitude);
              AppSnackBar.showSuccess(context, 'Location coordinates retrieved!');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to get current location: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyles.headingSemiBold.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          maxLines: null,
          minLines: 1,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 15),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.blue2.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.blue2.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue1),
            ),
            suffixIcon: _isLoadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location_rounded, color: AppColors.blue1),
                    tooltip: 'Get Current Location',
                    onPressed: _getCurrentLocation,
                  ),
          ),
          validator: widget.validator,
          onChanged: _onTextChanged,
        ),
        if (_isLoadingSuggestions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
            ),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue2.withValues(alpha: 0.3)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.blue3, height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(
                    suggestion['display_name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  onTap: () {
                    widget.controller.text = suggestion['display_name'] ?? '';
                    widget.onLocationChanged(
                      suggestion['display_name'] ?? '',
                      suggestion['lat'] ?? 0.0,
                      suggestion['lon'] ?? 0.0,
                    );
                    setState(() {
                      _suggestions = [];
                    });
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
