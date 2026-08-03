import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribes to the root-messages stream for [chatId].
class InitChatStream extends ChatEvent {
  final String chatId;
  final String partnerId;

  const InitChatStream({required this.chatId, required this.partnerId});

  @override
  List<Object?> get props => [chatId, partnerId];
}

/// Internal event fired on each stream emission.
class ChatStreamUpdated extends ChatEvent {
  final List<ChatMessage> messages;

  const ChatStreamUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Send a root-level message (no parentMessageId).
class SendMessage extends ChatEvent {
  final String content;
  final String? imageUrl;
  final bool isPrescription;

  const SendMessage({
    required this.content,
    this.imageUrl,
    this.isPrescription = false,
  });

  @override
  List<Object?> get props => [content, imageUrl, isPrescription];
}
