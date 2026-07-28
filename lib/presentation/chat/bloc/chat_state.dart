import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  /// Root messages only (parent_message_id IS NULL), sorted ascending.
  final List<ChatMessage> rootMessages;
  final String chatId;

  const ChatLoaded({
    required this.rootMessages,
    required this.chatId,
  });

  @override
  List<Object?> get props => [rootMessages, chatId];
}

class ChatFailure extends ChatState {
  final String message;

  const ChatFailure(this.message);

  @override
  List<Object?> get props => [message];
}
