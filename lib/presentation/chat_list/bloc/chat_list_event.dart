import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

/// Initialise (or re-initialise) the Supabase realtime stream for the
/// partner's chat list.
class InitChatListStream extends ChatListEvent {
  final String partnerId;

  const InitChatListStream({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

/// Internal event fired each time the Supabase stream emits a new snapshot.
class ChatListStreamUpdated extends ChatListEvent {
  final List<dynamic> chats; // ChatRoomModel list

  const ChatListStreamUpdated(this.chats);

  @override
  List<Object?> get props => [chats];
}
