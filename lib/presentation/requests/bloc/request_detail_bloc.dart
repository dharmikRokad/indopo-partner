import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import 'request_detail_event.dart';
import 'request_detail_state.dart';

class RequestDetailBloc extends Bloc<RequestDetailEvent, RequestDetailState> {
  final RequestRepository _requestRepository;

  RequestDetailBloc({
    required RequestRepository requestRepository,
    RequestModel? request,
  })  : _requestRepository = requestRepository,
        super(request != null ? RequestDetailLoaded(request) : RequestDetailInitial()) {
    on<FetchRequestDetail>(_onFetchRequestDetail);
    on<AcceptRequest>(_onAcceptRequest);
    on<RejectRequest>(_onRejectRequest);
    on<CompleteRequest>(_onCompleteRequest);
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
      // Rejecting/Cancelling updates status to Cancelled
      final request = await _requestRepository.updateRequestStatus(
        event.id,
        RequestStatus.cancelled,
        rejectionReason: event.reason,
      );
      emit(RequestActionSuccess(request, 'reject'));
    } catch (e) {
      emit(RequestDetailFailure(e.toString()));
    }
  }

  Future<void> _onCompleteRequest(
    CompleteRequest event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(RequestDetailLoading());
    try {
      // Completing updates status to Completed
      final request = await _requestRepository.updateRequestStatus(
        event.id,
        RequestStatus.completed,
      );
      emit(RequestActionSuccess(request, 'complete'));
    } catch (e) {
      emit(RequestDetailFailure(e.toString()));
    }
  }
}
