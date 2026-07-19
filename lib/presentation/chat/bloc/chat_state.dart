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
  final List<ChatMessage> messages;

  const ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatFailure extends ChatState {
  final String message;

  const ChatFailure(this.message);

  @override
  List<Object?> get props => [message];
}
