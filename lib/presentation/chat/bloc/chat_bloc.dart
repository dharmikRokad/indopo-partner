import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SupabaseChatRepository _supabaseChatRepository;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  String? _chatId;
  String? _appointmentId;
  String? _partnerId;

  ChatBloc({
    required SupabaseChatRepository supabaseChatRepository,
  })  : _supabaseChatRepository = supabaseChatRepository,
        super(ChatInitial()) {
    on<InitChatStream>(_onInitChatStream);
    on<StreamUpdated>(_onStreamUpdated);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onInitChatStream(
    InitChatStream event,
    Emitter<ChatState> emit,
  ) async {
    _chatId = event.chatId;
    _appointmentId = event.appointmentId;
    _partnerId = event.partnerId;

    emit(ChatLoading());

    await _messagesSubscription?.cancel();

    // Mark partner unread count as 0 when viewing this chat
    await _supabaseChatRepository.markPartnerUnreadAsRead(_chatId!);

    _messagesSubscription = _supabaseChatRepository
        .streamMessages(_chatId!)
        .listen(
          (messages) => add(StreamUpdated(messages)),
          onError: (err) {
            if (!isClosed) {
              add(StreamUpdated(const []));
            }
          },
        );
  }

  void _onStreamUpdated(
    StreamUpdated event,
    Emitter<ChatState> emit,
  ) {
    if (_chatId == null || _appointmentId == null) return;
    emit(ChatLoaded(
      messages: event.messages,
      chatId: _chatId!,
      appointmentId: _appointmentId!,
    ));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_chatId == null || _appointmentId == null || _partnerId == null) return;

    try {
      await _supabaseChatRepository.sendMessage(
        chatId: _chatId!,
        appointmentId: _appointmentId!,
        senderId: _partnerId!,
        senderRole: 'partner',
        content: event.content,
        imageUrl: event.imageUrl,
      );
    } catch (e) {
      print('[ChatBloc] SendMessage error: $e');
      // If error occurs (e.g. limit reached), emit failure temporarily or log
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
