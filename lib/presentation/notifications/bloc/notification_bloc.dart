import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'notification_event.dart';
import 'notification_state.dart';
import '../../../core/services/push_notification_service.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  Timer? _simulatedNotificationTimer;
  StreamSubscription? _foregroundSub;
  StreamSubscription? _openedSub;

  NotificationBloc() : super(NotificationState.initial()) {
    on<InitNotifications>(_onInitNotifications);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationTapped>(_onNotificationTapped);
  }

  void _onInitNotifications(
    InitNotifications event,
    Emitter<NotificationState> emit,
  ) {
    _foregroundSub?.cancel();
    _openedSub?.cancel();

    _foregroundSub = PushNotificationService
        .instance
        .foregroundNotificationStream
        .listen((notification) {
          add(NotificationReceived(notification));
        });

    _openedSub = PushNotificationService.instance.notificationOpenedStream
        .listen((notification) {
          add(NotificationTapped(notification));
        });

    print(
      '[FCM] Initializing FCM notifications listener for backend notifications...',
    );
  }

  void _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    emit(
      state.copyWith(
        status: NotificationStatus.foregroundReceived,
        notification: event.notification,
      ),
    );
  }

  void _onNotificationTapped(
    NotificationTapped event,
    Emitter<NotificationState> emit,
  ) {
    emit(
      state.copyWith(
        status: NotificationStatus.opened,
        notification: event.notification,
      ),
    );
  }

  @override
  Future<void> close() {
    _simulatedNotificationTimer?.cancel();
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    return super.close();
  }
}
