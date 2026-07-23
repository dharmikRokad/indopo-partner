import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class InitNotifications extends NotificationEvent {}

class NotificationReceived extends NotificationEvent {
  final NotificationModel notification;

  const NotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationTapped extends NotificationEvent {
  final NotificationModel notification;

  const NotificationTapped(this.notification);

  @override
  List<Object?> get props => [notification];
}
