import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatHistory extends ChatEvent {
  final String requestId;

  const LoadChatHistory(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class SendMessage extends ChatEvent {
  final String content;
  final String? imageUrl;

  const SendMessage({required this.content, this.imageUrl});

  @override
  List<Object?> get props => [content, imageUrl];
}

class MessageReceived extends ChatEvent {
  final ChatMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}
