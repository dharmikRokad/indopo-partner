import 'package:equatable/equatable.dart';
import '../../../data/models/request_model.dart';

enum RequestDetailStatus { initial, loading, loaded, actionSuccess, failure }

class RequestDetailState extends Equatable {
  static const Object _kNoChange = Object();

  final RequestDetailStatus status;
  final RequestModel? request;
  final String? actionType; // 'accept' | 'reject' | 'complete' | 'start_chat'
  final String? chatId;
  final String? errorMessage;

  const RequestDetailState({
    this.status = RequestDetailStatus.initial,
    this.request,
    this.actionType,
    this.chatId,
    this.errorMessage,
  });

  factory RequestDetailState.initial() =>
      const RequestDetailState(status: RequestDetailStatus.initial);

  RequestDetailState copyWith({
    RequestDetailStatus? status,
    Object? request = _kNoChange,
    Object? actionType = _kNoChange,
    Object? chatId = _kNoChange,
    Object? errorMessage = _kNoChange,
  }) {
    return RequestDetailState(
      status: status ?? this.status,
      request: request == _kNoChange ? this.request : request as RequestModel?,
      actionType: actionType == _kNoChange
          ? this.actionType
          : actionType as String?,
      chatId: chatId == _kNoChange ? this.chatId : chatId as String?,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    request,
    actionType,
    chatId,
    errorMessage,
  ];
}
