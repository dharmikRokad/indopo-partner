import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/request_repo.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final RequestRepository _requestRepository;

  AppointmentBloc({
    required RequestRepository requestRepository,
  })  : _requestRepository = requestRepository,
        super(AppointmentInitial()) {
    on<AssignAppointment>(_onAssignAppointment);
  }

  Future<void> _onAssignAppointment(
    AssignAppointment event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      final assigned = await _requestRepository.assignAppointment(event.appointment);
      emit(AppointmentAssigned(assigned));
    } catch (e) {
      emit(AppointmentFailed(e.toString()));
    }
  }
}
