import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/request_model.dart';
import '../../../data/repositories/request_repo.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import 'request_detail_event.dart';
import 'request_detail_state.dart';

class RequestDetailBloc extends Bloc<RequestDetailEvent, RequestDetailState> {
  final RequestRepository _requestRepository;
  final SupabaseChatRepository? _supabaseChatRepository;

  RequestDetailBloc({
    required RequestRepository requestRepository,
    SupabaseChatRepository? supabaseChatRepository,
    RequestModel? request,
  })  : _requestRepository = requestRepository,
        _supabaseChatRepository = supabaseChatRepository,
        super(request != null
            ? RequestDetailState.initial().copyWith(
                status: RequestDetailStatus.loaded,
                request: request,
              )
            : RequestDetailState.initial()) {
    on<FetchRequestDetail>(_onFetchRequestDetail);
    on<AcceptRequest>(_onAcceptRequest);
    on<RejectRequest>(_onRejectRequest);
    on<CompleteRequest>(_onCompleteRequest);
    on<StartPrescriptionChat>(_onStartPrescriptionChat);
    on<AppointmentConfirmed>(_onAppointmentConfirmed);
  }

  void _onAppointmentConfirmed(
    AppointmentConfirmed event,
    Emitter<RequestDetailState> emit,
  ) {
    final currentReq = state.request;
    if (currentReq != null) {
      final token = event.appointment.appointmentNumber?.toString();
      final updated = currentReq.copyWith(
        status: RequestStatus.inProgress,
        tokenNumber: token,
      );
      emit(state.copyWith(
        status: RequestDetailStatus.loaded,
        request: updated,
      ));
    }
  }

  Future<void> _onStartPrescriptionChat(
    StartPrescriptionChat event,
    Emitter<RequestDetailState> emit,
  ) async {
    final currentRequest = state.request;

    emit(state.copyWith(
      status: RequestDetailStatus.loading,
      errorMessage: null,
    ));
    try {
      String? chatId;
      if (_supabaseChatRepository != null) {
        chatId = await _supabaseChatRepository.openPrescriptionChat(
          patientId: event.patientId ?? currentRequest?.patientId ?? '',
          prescriptionUrl: event.prescriptionUrl ??
              (currentRequest?.attachments.isNotEmpty == true
                  ? currentRequest!.attachments.first
                  : ''),
          notes: event.notes ?? currentRequest?.description,
          partnerId: event.partnerId,
          notificationId:
              event.notificationId ?? currentRequest?.notificationId ?? event.id,
        );
      }

      final req = currentRequest ??
          RequestModel(
            id: event.id,
            patientId: event.patientId,
            notificationId: event.notificationId,
            chatId: chatId,
            patientName: 'Patient',
            patientAge: 30,
            patientGender: 'Other',
            patientContact: '',
            description: event.notes ?? '',
            attachments:
                event.prescriptionUrl != null ? [event.prescriptionUrl!] : [],
            timestamp: DateTime.now(),
            status: RequestStatus.inProgress,
          );

      emit(state.copyWith(
        status: RequestDetailStatus.actionSuccess,
        request: req,
        actionType: 'start_chat',
        chatId: chatId,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RequestDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFetchRequestDetail(
    FetchRequestDetail event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestDetailStatus.loading,
      errorMessage: null,
    ));
    try {
      final request = await _requestRepository.fetchRequestById(event.id);
      emit(state.copyWith(
        status: RequestDetailStatus.loaded,
        request: request,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RequestDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAcceptRequest(
    AcceptRequest event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestDetailStatus.loading,
      errorMessage: null,
    ));
    try {
      // 1. Update appointment status in primary backend repository
      final request = await _requestRepository.updateRequestStatus(
        event.id,
        RequestStatus.inProgress,
      );

      String? chatId;
      // 2. Get or create Supabase real-time chat room if repository is available
      if (_supabaseChatRepository != null &&
          event.patientId != null &&
          event.partnerId != null) {
        try {
          final room = await _supabaseChatRepository.getOrCreateChatRoom(
            patientId: event.patientId!,
            partnerId: event.partnerId!,
            patientName: event.patientName,
            partnerName: event.partnerName,
          );
          chatId = room.id;
        } catch (chatErr) {
          print('[RequestDetailBloc] Chat room creation error: $chatErr');
        }
      }

      emit(state.copyWith(
        status: RequestDetailStatus.actionSuccess,
        request: request,
        actionType: 'accept',
        chatId: chatId,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RequestDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRejectRequest(
    RejectRequest event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestDetailStatus.loading,
      errorMessage: null,
    ));
    try {
      final request = await _requestRepository.updateRequestStatus(
        event.id,
        RequestStatus.cancelled,
        rejectionReason: event.reason,
      );
      emit(state.copyWith(
        status: RequestDetailStatus.actionSuccess,
        request: request,
        actionType: 'reject',
        chatId: null,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RequestDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCompleteRequest(
    CompleteRequest event,
    Emitter<RequestDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestDetailStatus.loading,
      errorMessage: null,
    ));
    try {
      final request = await _requestRepository.updateRequestStatus(
        event.id,
        RequestStatus.completed,
      );
      emit(state.copyWith(
        status: RequestDetailStatus.actionSuccess,
        request: request,
        actionType: 'complete',
        chatId: null,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RequestDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
