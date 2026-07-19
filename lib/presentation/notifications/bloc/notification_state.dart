import 'package:equatable/equatable.dart';
import '../../../data/models/request_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationForegroundReceived extends NotificationState {
  final RequestModel request;

  const NotificationForegroundReceived(this.request);

  @override
  List<Object?> get props => [request];
}

class NotificationOpened extends NotificationState {
  final String requestId;

  const NotificationOpened(this.requestId);

  @override
  List<Object?> get props => [requestId];
}
