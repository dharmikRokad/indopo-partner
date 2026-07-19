import 'package:equatable/equatable.dart';
import '../../../data/models/request_model.dart';

abstract class RequestDetailState extends Equatable {
  const RequestDetailState();

  @override
  List<Object?> get props => [];
}

class RequestDetailInitial extends RequestDetailState {}

class RequestDetailLoading extends RequestDetailState {}

class RequestDetailLoaded extends RequestDetailState {
  final RequestModel request;

  const RequestDetailLoaded(this.request);

  @override
  List<Object?> get props => [request];
}

class RequestActionSuccess extends RequestDetailState {
  final RequestModel request;
  final String actionType; // 'accept' or 'reject'

  const RequestActionSuccess(this.request, this.actionType);

  @override
  List<Object?> get props => [request, actionType];
}

class RequestDetailFailure extends RequestDetailState {
  final String message;

  const RequestDetailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
