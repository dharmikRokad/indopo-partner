import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class InitChatStream extends ChatEvent {
  final String chatId;
  final String appointmentId;
  final String partnerId;

  const InitChatStream({
    required this.chatId,
    required this.appointmentId,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [chatId, appointmentId, partnerId];
}

class StreamUpdated extends ChatEvent {
  final List<ChatMessage> messages;

  const StreamUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

class SendMessage extends ChatEvent {
  final String content;
  final String? imageUrl;

  const SendMessage({required this.content, this.imageUrl});

  @override
  List<Object?> get props => [content, imageUrl];
}
