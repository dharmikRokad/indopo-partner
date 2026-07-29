import 'package:flutter_bloc/flutter_bloc.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';
import '../../../data/repositories/request_repo.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final RequestRepository _requestRepository;

  AppointmentBloc({
    required RequestRepository requestRepository,
  })  : _requestRepository = requestRepository,
        super(AppointmentState.initial()) {
    on<AssignAppointment>(_onAssignAppointment);
  }

  Future<void> _onAssignAppointment(
    AssignAppointment event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(state.copyWith(
      status: AppointmentStatus.loading,
      errorMessage: null,
    ));
    try {
      final assigned = await _requestRepository.assignAppointment(event.appointment);
      emit(state.copyWith(
        status: AppointmentStatus.assigned,
        appointment: assigned,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AppointmentStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
