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
  final String chatId;
  final String appointmentId;

  const ChatLoaded({
    required this.messages,
    required this.chatId,
    required this.appointmentId,
  });

  int get patientMessageCount =>
      messages.where((m) => m.senderRole == 'patient' && m.appointmentId == appointmentId).length;

  int get partnerMessageCount =>
      messages.where((m) => m.senderRole == 'partner' && m.appointmentId == appointmentId).length;

  @override
  List<Object?> get props => [messages, chatId, appointmentId];
}

class ChatFailure extends ChatState {
  final String message;

  const ChatFailure(this.message);

  @override
  List<Object?> get props => [message];
}
