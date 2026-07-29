import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

enum ChatStatus { initial, loading, loaded, failure }

class ChatState extends Equatable {
  static const Object _kNoChange = Object();

  final ChatStatus status;
  final List<ChatMessage> rootMessages;
  final String? chatId;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.rootMessages = const [],
    this.chatId,
    this.errorMessage,
  });

  factory ChatState.initial() => const ChatState(status: ChatStatus.initial);

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? rootMessages,
    Object? chatId = _kNoChange,
    Object? errorMessage = _kNoChange,
  }) {
    return ChatState(
      status: status ?? this.status,
      rootMessages: rootMessages ?? this.rootMessages,
      chatId: chatId == _kNoChange ? this.chatId : chatId as String?,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, rootMessages, chatId, errorMessage];
}
