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
  final String? partnerName;
  final String? patientId;

  const InitChatStream({
    required this.chatId,
    required this.partnerId,
    this.partnerName,
    this.patientId,
  });

  @override
  List<Object?> get props => [chatId, partnerId, partnerName, patientId];
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
  final String? partnerName;
  final String? patientId;

  const SendMessage({
    required this.content,
    this.imageUrl,
    this.isPrescription = false,
    this.partnerName,
    this.patientId,
  });

  @override
  List<Object?> get props => [
    content,
    imageUrl,
    isPrescription,
    partnerName,
    patientId,
  ];
}
