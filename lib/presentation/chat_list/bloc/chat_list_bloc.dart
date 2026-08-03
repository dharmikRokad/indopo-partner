import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_room_model.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final SupabaseChatRepository _repo;
  StreamSubscription<List<ChatRoomModel>>? _subscription;

  ChatListBloc({required SupabaseChatRepository repo})
    : _repo = repo,
      super(ChatListState.initial()) {
    on<InitChatListStream>(_onInitChatListStream);
    on<ChatListStreamUpdated>(_onChatListStreamUpdated);
  }

  Future<void> _onInitChatListStream(
    InitChatListStream event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading));
    await _subscription?.cancel();

    _subscription = _repo
        .streamPartnerChats(event.partnerId)
        .listen(
          (chats) => add(ChatListStreamUpdated(chats)),
          onError: (err) {
            debugPrint('[ChatListBloc] stream error: $err');
            if (!isClosed) add(const ChatListStreamUpdated(const []));
          },
        );
  }

  void _onChatListStreamUpdated(
    ChatListStreamUpdated event,
    Emitter<ChatListState> emit,
  ) {
    final chats = List<ChatRoomModel>.from(event.chats);
    // Sort by most recent message; nulls go to the end
    chats.sort((a, b) {
      final aTime = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    emit(state.copyWith(status: ChatListStatus.loaded, chats: chats));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
