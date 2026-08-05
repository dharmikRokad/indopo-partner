import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import 'request_list_event.dart';
import 'request_list_state.dart';

class RequestListBloc extends Bloc<RequestListEvent, RequestListState> {
  final RequestRepository _requestRepository;
  final bool isMedical;

  RequestListBloc({required this._requestRepository, this.isMedical = false})
    : super(RequestListState.initial()) {
    on<FetchRequests>(_onFetchRequests);
    on<RequestReceived>(_onRequestReceived);
  }

  Future<void> _onFetchRequests(
    FetchRequests event,
    Emitter<RequestListState> emit,
  ) async {
    final previousHasUnread = state.hasUnreadNew;
    final dateToUse =
        event.status == RequestStatus.inProgress ? event.date : null;
    emit(
      state.copyWith(
        status: RequestListStatus.loading,
        selectedDate: dateToUse,
        errorMessage: null,
      ),
    );

    try {
      final list = await _requestRepository.fetchRequests(
        event.status,
        isMedical: isMedical,
        date: dateToUse,
      );

      // Determine if there are unread/new requests (to display unread notification dot)
      bool hasUnread = false;
      if (event.status == RequestStatus.newRequest) {
        hasUnread = list.isNotEmpty;
      } else {
        if (state.status == RequestListStatus.loaded) {
          hasUnread = previousHasUnread;
        } else {
          final newReqs = await _requestRepository.fetchRequests(
            RequestStatus.newRequest,
            isMedical: isMedical,
          );
          hasUnread = newReqs.isNotEmpty;
        }
      }

      emit(
        state.copyWith(
          status: RequestListStatus.loaded,
          requests: list,
          requestStatus: event.status,
          selectedDate: dateToUse,
          hasUnreadNew: hasUnread,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RequestListStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onRequestReceived(
    RequestReceived event,
    Emitter<RequestListState> emit,
  ) {
    if (state.status != RequestListStatus.loaded) return;

    final updatedList = List<RequestModel>.from(state.requests);

    // If notification belongs to the active tab status, add to screen list
    if (event.request.status == state.requestStatus) {
      updatedList.insert(0, event.request);
    }

    emit(
      state.copyWith(
        requests: updatedList,
        hasUnreadNew: true, // Incoming is always unread/new
      ),
    );
  }
}
