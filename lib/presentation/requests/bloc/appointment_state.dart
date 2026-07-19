import 'package:equatable/equatable.dart';
import '../../../data/models/appointment_model.dart';

abstract class AppointmentState extends Equatable {
  const AppointmentState();

  @override
  List<Object?> get props => [];
}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentAssigned extends AppointmentState {
  final AppointmentModel appointment;

  const AppointmentAssigned(this.appointment);

  @override
  List<Object?> get props => [appointment];
}

class AppointmentFailed extends AppointmentState {
  final String message;

  const AppointmentFailed(this.message);

  @override
  List<Object?> get props => [message];
}
