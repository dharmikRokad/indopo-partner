import 'package:equatable/equatable.dart';
import '../../../data/models/appointment_model.dart';

enum AppointmentStatus { initial, loading, assigned, failure }

class AppointmentState extends Equatable {
  static const Object _kNoChange = Object();

  final AppointmentStatus status;
  final AppointmentModel? appointment;
  final String? errorMessage;

  const AppointmentState({
    this.status = AppointmentStatus.initial,
    this.appointment,
    this.errorMessage,
  });

  factory AppointmentState.initial() =>
      const AppointmentState(status: AppointmentStatus.initial);

  AppointmentState copyWith({
    AppointmentStatus? status,
    Object? appointment = _kNoChange,
    Object? errorMessage = _kNoChange,
  }) {
    return AppointmentState(
      status: status ?? this.status,
      appointment: appointment == _kNoChange
          ? this.appointment
          : appointment as AppointmentModel?,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, appointment, errorMessage];
}
