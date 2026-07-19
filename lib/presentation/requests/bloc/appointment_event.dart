import 'package:equatable/equatable.dart';
import '../../../data/models/appointment_model.dart';

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object?> get props => [];
}

class AssignAppointment extends AppointmentEvent {
  final AppointmentModel appointment;

  const AssignAppointment(this.appointment);

  @override
  List<Object?> get props => [appointment];
}
