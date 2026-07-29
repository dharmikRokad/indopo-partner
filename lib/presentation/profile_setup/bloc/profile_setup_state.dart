import 'package:equatable/equatable.dart';
import '../../../data/models/partner_model.dart';

enum ProfileSetupStatus { initial, loading, success, failure }

class ProfileSetupState extends Equatable {
  static const Object _kNoChange = Object();

  final ProfileSetupStatus status;
  final int step;
  final PartnerModel? partner;
  final String? errorMessage;

  const ProfileSetupState({
    this.status = ProfileSetupStatus.initial,
    this.step = 0,
    this.partner,
    this.errorMessage,
  });

  factory ProfileSetupState.initial() =>
      const ProfileSetupState(status: ProfileSetupStatus.initial);

  ProfileSetupState copyWith({
    ProfileSetupStatus? status,
    int? step,
    Object? partner = _kNoChange,
    Object? errorMessage = _kNoChange,
  }) {
    return ProfileSetupState(
      status: status ?? this.status,
      step: step ?? this.step,
      partner:
          partner == _kNoChange ? this.partner : partner as PartnerModel?,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, step, partner, errorMessage];
}
