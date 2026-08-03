import 'package:equatable/equatable.dart';
import '../../../data/models/chat_message.dart';

enum ThreadStatus { initial, loading, loaded, failure }

class ThreadState extends Equatable {
  static const Object _kNoChange = Object();

  final ThreadStatus status;
  final List<ChatMessage> replies;
  final String? parentMessageId;
  final String? errorMessage;

  const ThreadState({
    this.status = ThreadStatus.initial,
    this.replies = const [],
    this.parentMessageId,
    this.errorMessage,
  });

  factory ThreadState.initial() =>
      const ThreadState(status: ThreadStatus.initial);

  ThreadState copyWith({
    ThreadStatus? status,
    List<ChatMessage>? replies,
    Object? parentMessageId = _kNoChange,
    Object? errorMessage = _kNoChange,
  }) {
    return ThreadState(
      status: status ?? this.status,
      replies: replies ?? this.replies,
      parentMessageId: parentMessageId == _kNoChange
          ? this.parentMessageId
          : parentMessageId as String?,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, replies, parentMessageId, errorMessage];
}
