import 'package:equatable/equatable.dart';
import '../../../data/models/request_model.dart';

abstract class RequestListEvent extends Equatable {
  const RequestListEvent();

  @override
  List<Object?> get props => [];
}

class FetchRequests extends RequestListEvent {
  final RequestStatus status;

  const FetchRequests(this.status);

  @override
  List<Object?> get props => [status];
}

class RequestReceived extends RequestListEvent {
  final RequestModel request;

  const RequestReceived(this.request);

  @override
  List<Object?> get props => [request];
}
