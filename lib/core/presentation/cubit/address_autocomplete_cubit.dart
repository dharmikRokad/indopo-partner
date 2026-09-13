import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/location_service.dart';
import '../../../data/repositories/profile_repo.dart';

class AddressAutocompleteState extends Equatable {
  final List<Map<String, dynamic>> suggestions;
  final bool isLoadingSuggestions;
  final bool isLoadingLocation;
  final String? errorMessage;
  final String? successMessage;

  const AddressAutocompleteState({
    this.suggestions = const [],
    this.isLoadingSuggestions = false,
    this.isLoadingLocation = false,
    this.errorMessage,
    this.successMessage,
  });

  AddressAutocompleteState copyWith({
    List<Map<String, dynamic>>? suggestions,
    bool? isLoadingSuggestions,
    bool? isLoadingLocation,
    String? errorMessage,
    String? successMessage,
  }) {
    return AddressAutocompleteState(
      suggestions: suggestions ?? this.suggestions,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        suggestions,
        isLoadingSuggestions,
        isLoadingLocation,
        errorMessage,
        successMessage,
      ];
}

class AddressAutocompleteCubit extends Cubit<AddressAutocompleteState> {
  Timer? _debounce;

  AddressAutocompleteCubit() : super(const AddressAutocompleteState());

  void onTextChanged(String query, ProfileRepository repo) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      emit(state.copyWith(suggestions: [], isLoadingSuggestions: false));
      return;
    }

    emit(state.copyWith(isLoadingSuggestions: true));

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final suggestions = await repo.getAddressSuggestions(query);
        if (!isClosed) {
          emit(state.copyWith(
            suggestions: suggestions,
            isLoadingSuggestions: false,
          ));
        }
      } catch (e) {
        if (!isClosed) {
          emit(state.copyWith(
            suggestions: [],
            isLoadingSuggestions: false,
          ));
        }
      }
    });
  }

  void clearSuggestions() {
    emit(state.copyWith(suggestions: [], isLoadingSuggestions: false));
  }

  Future<void> getCurrentLocation(
    BuildContext context,
    ProfileRepository repo,
    TextEditingController controller,
    Function(String address, double lat, double long) onLocationChanged,
  ) async {
    emit(state.copyWith(
      isLoadingLocation: true,
      errorMessage: null,
      successMessage: null,
    ));

    try {
      final position = await LocationService.instance.getCurrentLocation(context);
      if (position != null) {
        final address = await repo.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        final selectedAddress = address ??
            'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';

        controller.text = selectedAddress;
        onLocationChanged(
          selectedAddress,
          position.latitude,
          position.longitude,
        );

        if (!isClosed) {
          emit(state.copyWith(
            isLoadingLocation: false,
            successMessage: address != null
                ? 'Location retrieved successfully!'
                : 'Location coordinates retrieved!',
          ));
        }
      } else {
        if (!isClosed) {
          emit(state.copyWith(isLoadingLocation: false));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          isLoadingLocation: false,
          errorMessage: 'Failed to get current location: $e',
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
