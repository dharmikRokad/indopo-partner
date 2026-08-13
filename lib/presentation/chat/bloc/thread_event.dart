import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

abstract class ThreadEvent extends Equatable {
  const ThreadEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the reply stream for [parentMessageId].
class InitThreadStream extends ThreadEvent {
  final String chatId;
  final String parentMessageId;
  final String partnerId;
  final String? partnerName;
  final String? patientId;

  const InitThreadStream({
    required this.chatId,
    required this.parentMessageId,
    required this.partnerId,
    this.partnerName,
    this.patientId,
  });

  @override
  List<Object?> get props => [
    chatId,
    parentMessageId,
    partnerId,
    partnerName,
    patientId,
  ];
}

/// Internal event fired on each stream emission.
class ThreadStreamUpdated extends ThreadEvent {
  final List<ChatMessage> replies;

  const ThreadStreamUpdated(this.replies);

  @override
  List<Object?> get props => [replies];
}

/// Send a reply inside the thread.
class SendThreadReply extends ThreadEvent {
  final String content;
  final String? imageUrl;
  final String? partnerName;
  final String? patientId;

  const SendThreadReply({
    required this.content,
    this.imageUrl,
    this.partnerName,
    this.patientId,
  });

  @override
  List<Object?> get props => [content, imageUrl, partnerName, patientId];
}
