import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/supabase_chat_repo.dart';
import 'thread_event.dart';
import 'thread_state.dart';

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final SupabaseChatRepository _repo;
  StreamSubscription<List<ChatMessage>>? _repliesSubscription;

  String? _chatId;
  String? _parentMessageId;
  String? _partnerId;

  ThreadBloc({required SupabaseChatRepository repo})
      : _repo = repo,
        super(ThreadState.initial()) {
    on<InitThreadStream>(_onInitThreadStream);
    on<ThreadStreamUpdated>(_onThreadStreamUpdated);
    on<SendThreadReply>(_onSendThreadReply);
  }

  Future<void> _onInitThreadStream(
    InitThreadStream event,
    Emitter<ThreadState> emit,
  ) async {
    _chatId = event.chatId;
    _parentMessageId = event.parentMessageId;
    _partnerId = event.partnerId;

    emit(state.copyWith(status: ThreadStatus.loading));
    await _repliesSubscription?.cancel();

    // Mark unread replies as read when partner opens the thread
    await _repo.markThreadUnreadAsRead(_parentMessageId!);

    _repliesSubscription =
        _repo.streamThreadReplies(_parentMessageId!).listen(
      (replies) => add(ThreadStreamUpdated(replies)),
      onError: (err) {
        debugPrint('[ThreadBloc] stream error: $err');
        if (!isClosed) add(const ThreadStreamUpdated([]));
      },
    );
  }

  void _onThreadStreamUpdated(
    ThreadStreamUpdated event,
    Emitter<ThreadState> emit,
  ) {
    if (_parentMessageId == null) return;
    emit(state.copyWith(
      status: ThreadStatus.loaded,
      replies: event.replies,
      parentMessageId: _parentMessageId,
    ));
  }

  Future<void> _onSendThreadReply(
    SendThreadReply event,
    Emitter<ThreadState> emit,
  ) async {
    if (_chatId == null || _parentMessageId == null || _partnerId == null) {
      return;
    }

    try {
      await _repo.sendMessage(
        chatId: _chatId!,
        senderId: _partnerId!,
        senderRole: 'PARTNER',
        content: event.content,
        imageUrl: event.imageUrl,
        parentMessageId: _parentMessageId,
      );
      // The stream subscription will automatically emit the updated list
    } catch (e) {
      debugPrint('[ThreadBloc] SendThreadReply error: $e');
      // Stream will still show correct state; error is silently logged
    }
  }

  @override
  Future<void> close() {
    _repliesSubscription?.cancel();
    return super.close();
  }
}
