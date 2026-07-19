import 'package:equatable/equatable.dart';

abstract class ProfileSetupEvent extends Equatable {
  const ProfileSetupEvent();

  @override
  List<Object?> get props => [];
}

class ProfileStepChanged extends ProfileSetupEvent {
  final int step;

  const ProfileStepChanged(this.step);

  @override
  List<Object?> get props => [step];
}

class ProfileSubmitted extends ProfileSetupEvent {
  final Map<String, dynamic> details;

  const ProfileSubmitted(this.details);

  @override
  List<Object?> get props => [details];
}
