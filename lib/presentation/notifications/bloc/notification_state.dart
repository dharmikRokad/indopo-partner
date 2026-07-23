import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationForegroundReceived extends NotificationState {
  final NotificationModel notification;

  const NotificationForegroundReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationOpened extends NotificationState {
  final NotificationModel notification;

  const NotificationOpened(this.notification);

  @override
  List<Object?> get props => [notification];
}
