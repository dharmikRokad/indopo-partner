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
        super(const ProfileSetupInitial()) {
    on<ProfileStepChanged>(_onProfileStepChanged);
    on<ProfileSubmitted>(_onProfileSubmitted);
  }

  void _onProfileStepChanged(
    ProfileStepChanged event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(ProfileStepState(event.step));
  }

  Future<void> _onProfileSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileSetupState> emit,
  ) async {
    final int currentStep = state is ProfileStepState 
        ? (state as ProfileStepState).step 
        : (state is ProfileSetupFailure ? (state as ProfileSetupFailure).step : 0);

    emit(ProfileSetupLoading(currentStep));

    try {
      final updatedPartner = _currentPartner.copyWith(
        isProfileConfigured: true,
        details: event.details,
      );

      final result = await _profileRepository.saveProfile(updatedPartner);
      emit(ProfileSetupSuccess(result));
    } catch (e) {
      emit(ProfileSetupFailure(e.toString(), currentStep));
    }
  }
}
