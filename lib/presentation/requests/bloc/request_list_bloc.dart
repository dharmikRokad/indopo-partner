import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import 'request_list_event.dart';
import 'request_list_state.dart';

class RequestListBloc extends Bloc<RequestListEvent, RequestListState> {
  final RequestRepository _requestRepository;

  RequestListBloc({
    required RequestRepository requestRepository,
  })  : _requestRepository = requestRepository,
        super(RequestListInitial()) {
    on<FetchRequests>(_onFetchRequests);
    on<RequestReceived>(_onRequestReceived);
  }

  Future<void> _onFetchRequests(
    FetchRequests event,
    Emitter<RequestListState> emit,
  ) async {
    final currentState = state;
    emit(RequestListLoading());

    try {
      final list = await _requestRepository.fetchRequests(event.status);
      
      // Determine if there are unread/new requests (to display unread notification dot)
      bool hasUnread = false;
      if (event.status == RequestStatus.newRequest) {
        hasUnread = list.isNotEmpty;
      } else {
        if (currentState is RequestListLoaded) {
          hasUnread = currentState.hasUnreadNew;
        } else {
          final newReqs = await _requestRepository.fetchRequests(RequestStatus.newRequest);
          hasUnread = newReqs.isNotEmpty;
        }
      }

      emit(RequestListLoaded(
        requests: list,
        status: event.status,
        hasUnreadNew: hasUnread,
      ));
    } catch (e) {
      emit(RequestListFailure(e.toString()));
    }
  }

  void _onRequestReceived(
    RequestReceived event,
    Emitter<RequestListState> emit,
  ) {
    final currentState = state;
    if (currentState is RequestListLoaded) {
      final updatedList = List<RequestModel>.from(currentState.requests);
      
      // If notification belongs to the active tab status, add to screen list
      if (event.request.status == currentState.status) {
        updatedList.insert(0, event.request);
      }

      emit(RequestListLoaded(
        requests: updatedList,
        status: currentState.status,
        hasUnreadNew: true, // Incoming is always unread/new
      ));
    }
  }
}
