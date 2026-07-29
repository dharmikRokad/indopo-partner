import 'package:equatable/equatable.dart';
import '../../../data/models/chat_room_model.dart';

enum ChatListStatus { initial, loading, loaded, error }

class ChatListState extends Equatable {
  static const Object _kNoChange = Object();

  final ChatListStatus status;
  final List<ChatRoomModel> chats;
  final String? errorMessage;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.chats = const [],
    this.errorMessage,
  });

  factory ChatListState.initial() =>
      const ChatListState(status: ChatListStatus.initial);

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatRoomModel>? chats,
    Object? errorMessage = _kNoChange,
  }) {
    return ChatListState(
      status: status ?? this.status,
      chats: chats ?? this.chats,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, chats, errorMessage];
}
