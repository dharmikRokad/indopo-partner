import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SupabaseChatRepository _repo;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  String? _chatId;
  String? _partnerId;

  ChatBloc({required SupabaseChatRepository repo})
      : _repo = repo,
        super(ChatInitial()) {
    on<InitChatStream>(_onInitChatStream);
    on<ChatStreamUpdated>(_onChatStreamUpdated);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onInitChatStream(
    InitChatStream event,
    Emitter<ChatState> emit,
  ) async {
    _chatId = event.chatId;
    _partnerId = event.partnerId;

    emit(ChatLoading());
    await _messagesSubscription?.cancel();

    // Reset partner unread count when entering the chat
    await _repo.markPartnerChatsUnreadAsRead(_chatId!);

    _messagesSubscription = _repo.streamRootMessages(_chatId!).listen(
      (messages) => add(ChatStreamUpdated(messages)),
      onError: (err) {
        debugPrint('[ChatBloc] stream error: $err');
        if (!isClosed) add(const ChatStreamUpdated([]));
      },
    );
  }

  void _onChatStreamUpdated(
    ChatStreamUpdated event,
    Emitter<ChatState> emit,
  ) {
    if (_chatId == null) return;
    emit(ChatLoaded(
      rootMessages: event.messages,
      chatId: _chatId!,
    ));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_chatId == null || _partnerId == null) return;

    try {
      await _repo.sendMessage(
        chatId: _chatId!,
        senderId: _partnerId!,
        senderRole: 'PARTNER',
        content: event.content,
        imageUrl: event.imageUrl,
        isPrescription: event.isPrescription,
      );
    } catch (e) {
      debugPrint('[ChatBloc] SendMessage error: $e');
      // Optionally emit ChatFailure here — for now silently log
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
