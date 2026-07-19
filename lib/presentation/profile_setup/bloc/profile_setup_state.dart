import 'package:equatable/equatable.dart';
import '../../../data/models/partner_model.dart';

abstract class ProfileSetupState extends Equatable {
  const ProfileSetupState();

  @override
  List<Object?> get props => [];
}

class ProfileSetupInitial extends ProfileSetupState {
  final int step;

  const ProfileSetupInitial({this.step = 0});

  @override
  List<Object?> get props => [step];
}

class ProfileStepState extends ProfileSetupState {
  final int step;

  const ProfileStepState(this.step);

  @override
  List<Object?> get props => [step];
}

class ProfileSetupLoading extends ProfileSetupState {
  final int step;

  const ProfileSetupLoading(this.step);

  @override
  List<Object?> get props => [step];
}

class ProfileSetupSuccess extends ProfileSetupState {
  final PartnerModel partner;

  const ProfileSetupSuccess(this.partner);

  @override
  List<Object?> get props => [partner];
}

class ProfileSetupFailure extends ProfileSetupState {
  final String message;
  final int step;

  const ProfileSetupFailure(this.message, this.step);

  @override
  List<Object?> get props => [message, step];
}
