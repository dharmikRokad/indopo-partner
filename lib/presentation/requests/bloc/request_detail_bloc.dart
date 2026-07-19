import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import 'request_detail_event.dart';
import 'request_detail_state.dart';

class RequestDetailBloc extends Bloc<RequestDetailEvent, RequestDetailState> {
  final RequestRepository _requestRepository;

  RequestDetailBloc({
    required RequestRepository requestRepository,
  })  : _requestRepository = requestRepository,
        super(RequestDetailInitial()) {
    on<FetchRequestDetail>(_onFetchRequestDetail);
    on<AcceptRequest>(_onAcceptRequest);
    on<RejectRequest>(_onRejectRequest);
  }

  Future<void> _onFetchRequestDetail(
    FetchRequestDetail event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(RequestDetailLoading());
    try {
      final request = await _requestRepository.fetchRequestById(event.id);
      emit(RequestDetailLoaded(request));
    } catch (e) {
      emit(RequestDetailFailure(e.toString()));
    }
  }

  Future<void> _onAcceptRequest(
    AcceptRequest event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(RequestDetailLoading());
    try {
      // Accepting updates status to In Progress
      final request = await _requestRepository.updateRequestStatus(
        event.id,
        RequestStatus.inProgress,
      );
      emit(RequestActionSuccess(request, 'accept'));
    } catch (e) {
      emit(RequestDetailFailure(e.toString()));
    }
  }

  Future<void> _onRejectRequest(
    RejectRequest event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(RequestDetailLoading());
    try {
      // Rejecting updates status to Completed with rejection reason
      final request = await _requestRepository.updateRequestStatus(
        event.id,
        RequestStatus.completed,
        rejectionReason: event.reason,
      );
      emit(RequestActionSuccess(request, 'reject'));
    } catch (e) {
      emit(RequestDetailFailure(e.toString()));
    }
  }
}
