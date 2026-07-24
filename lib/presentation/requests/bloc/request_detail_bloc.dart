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
        super(request != null ? RequestDetailLoaded(request) : RequestDetailInitial()) {
    on<FetchRequestDetail>(_onFetchRequestDetail);
    on<AcceptRequest>(_onAcceptRequest);
    on<RejectRequest>(_onRejectRequest);
    on<CompleteRequest>(_onCompleteRequest);
    on<StartPrescriptionChat>(_onStartPrescriptionChat);
  }

  Future<void> _onStartPrescriptionChat(
    StartPrescriptionChat event,
    Emitter<RequestDetailState> emit,
  ) async {
    final currentRequest = state is RequestDetailLoaded
        ? (state as RequestDetailLoaded).request
        : null;

    emit(RequestDetailLoading());
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
          notificationId: event.notificationId ?? currentRequest?.notificationId ?? event.id,
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
            attachments: event.prescriptionUrl != null ? [event.prescriptionUrl!] : [],
            timestamp: DateTime.now(),
            status: RequestStatus.inProgress,
          );

      emit(RequestActionSuccess(req, 'start_chat', chatId: chatId));
    } catch (e) {
      emit(RequestDetailFailure(e.toString()));
    }
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

      emit(RequestActionSuccess(request, 'accept', chatId: chatId));
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
