import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

abstract class ThreadState extends Equatable {
  const ThreadState();

  @override
  List<Object?> get props => [];
}

class ThreadInitial extends ThreadState {}

class ThreadLoading extends ThreadState {}

class ThreadLoaded extends ThreadState {
  final List<ChatMessage> replies;
  final String parentMessageId;

  const ThreadLoaded({
    required this.replies,
    required this.parentMessageId,
  });

  @override
  List<Object?> get props => [replies, parentMessageId];
}

class ThreadFailure extends ThreadState {
  final String message;

  const ThreadFailure(this.message);

  @override
  List<Object?> get props => [message];
}
