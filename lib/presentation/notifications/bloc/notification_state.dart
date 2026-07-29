import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

enum NotificationStatus { initial, foregroundReceived, opened }

class NotificationState extends Equatable {
  static const Object _kNoChange = Object();

  final NotificationStatus status;
  final NotificationModel? notification;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notification,
  });

  factory NotificationState.initial() =>
      const NotificationState(status: NotificationStatus.initial);

  NotificationState copyWith({
    NotificationStatus? status,
    Object? notification = _kNoChange,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notification: notification == _kNoChange
          ? this.notification
          : notification as NotificationModel?,
    );
  }

  @override
  List<Object?> get props => [status, notification];
}
