import 'package:equatable/equatable.dart';
import '../../../data/models/request_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class InitNotifications extends NotificationEvent {}

class NotificationReceived extends NotificationEvent {
  final RequestModel request;

  const NotificationReceived(this.request);

  @override
  List<Object?> get props => [request];
}

class NotificationTapped extends NotificationEvent {
  final String requestId;

  const NotificationTapped(this.requestId);

  @override
  List<Object?> get props => [requestId];
}
