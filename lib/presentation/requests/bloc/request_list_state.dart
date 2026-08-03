import 'package:equatable/equatable.dart';
import '../../../data/models/request_model.dart';

enum RequestListStatus { initial, loading, loaded, failure }

class RequestListState extends Equatable {
  static const Object _kNoChange = Object();

  final RequestListStatus status;
  final List<RequestModel> requests;
  final RequestStatus? requestStatus;
  final bool hasUnreadNew;
  final String? errorMessage;

  const RequestListState({
    this.status = RequestListStatus.initial,
    this.requests = const [],
    this.requestStatus,
    this.hasUnreadNew = false,
    this.errorMessage,
  });

  factory RequestListState.initial() =>
      const RequestListState(status: RequestListStatus.initial);

  RequestListState copyWith({
    RequestListStatus? status,
    List<RequestModel>? requests,
    Object? requestStatus = _kNoChange,
    bool? hasUnreadNew,
    Object? errorMessage = _kNoChange,
  }) {
    return RequestListState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      requestStatus: requestStatus == _kNoChange
          ? this.requestStatus
          : requestStatus as RequestStatus?,
      hasUnreadNew: hasUnreadNew ?? this.hasUnreadNew,
      errorMessage: errorMessage == _kNoChange
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    requests,
    requestStatus,
    hasUnreadNew,
    errorMessage,
  ];
}
