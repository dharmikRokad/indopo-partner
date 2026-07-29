import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/profile_repo.dart';
import 'profile_setup_event.dart';
import 'profile_setup_state.dart';

class ProfileSetupBloc extends Bloc<ProfileSetupEvent, ProfileSetupState> {
  final ProfileRepository _profileRepository;
  final PartnerModel _currentPartner;

  ProfileSetupBloc({
    required ProfileRepository profileRepository,
    required PartnerModel currentPartner,
  })  : _profileRepository = profileRepository,
        _currentPartner = currentPartner,
        super(ProfileSetupState.initial()) {
    on<ProfileStepChanged>(_onProfileStepChanged);
    on<ProfileSubmitted>(_onProfileSubmitted);
  }

  void _onProfileStepChanged(
    ProfileStepChanged event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(state.copyWith(
      status: ProfileSetupStatus.initial,
      step: event.step,
    ));
  }

  Future<void> _onProfileSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileSetupState> emit,
  ) async {
    final currentStep = state.step;

    emit(state.copyWith(
      status: ProfileSetupStatus.loading,
      errorMessage: null,
    ));

    try {
      final updatedPartner = _currentPartner.copyWith(
        isProfileConfigured: true,
        details: event.details,
      );

      final result = await _profileRepository.saveProfile(
        updatedPartner,
        profilePictureFile: event.profilePictureFile,
      );
      emit(state.copyWith(
        status: ProfileSetupStatus.success,
        partner: result,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileSetupStatus.failure,
        errorMessage: e.toString(),
        step: currentStep,
      ));
    }
  }
}
