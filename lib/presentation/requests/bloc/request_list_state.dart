import 'package:equatable/equatable.dart';
import '../../../data/models/request_model.dart';

abstract class RequestListState extends Equatable {
  const RequestListState();

  @override
  List<Object?> get props => [];
}

class RequestListInitial extends RequestListState {}

class RequestListLoading extends RequestListState {}

class RequestListLoaded extends RequestListState {
  final List<RequestModel> requests;
  final RequestStatus status;
  final bool hasUnreadNew;

  const RequestListLoaded({
    required this.requests,
    required this.status,
    required this.hasUnreadNew,
  });

  @override
  List<Object?> get props => [requests, status, hasUnreadNew];
}

class RequestListFailure extends RequestListState {
  final String message;

  const RequestListFailure(this.message);

  @override
  List<Object?> get props => [message];
}
