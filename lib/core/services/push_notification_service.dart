import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/notification_model.dart' hide NotificationResponse;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
    '[PushNotificationService] Background message received: ${message.messageId}',
  );
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
  playSound: true,
);

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  String? _fcmToken;
  final _foregroundNotificationController =
      StreamController<NotificationModel>.broadcast();
  final _notificationOpenedController =
      StreamController<NotificationModel>.broadcast();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? get fcmToken => _fcmToken;
  Stream<NotificationModel> get foregroundNotificationStream =>
      _foregroundNotificationController.stream;
  Stream<NotificationModel> get notificationOpenedStream =>
      _notificationOpenedController.stream;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      // Register background messaging handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permission
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications for Android foreground notifications banner
      if (Platform.isAndroid) {
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final jsonMap = jsonDecode(payload) as Map<String, dynamic>;
              _notificationOpenedController.add(
                NotificationModel.fromJson(jsonMap),
              );
            } catch (_) {
              _notificationOpenedController.add(
                _createFallbackNotification(payload),
              );
            }
          }
        },
      );

      // Configure foreground presentation options for iOS
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Get FCM token
      _fcmToken = await FirebaseMessaging.instance.getToken();
      print('[PushNotificationService] FCM Token: $_fcmToken');

      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _fcmToken = token;
        print('[PushNotificationService] FCM Token Refreshed: $_fcmToken');
      });

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
          '[PushNotificationService] Foreground message received: ${message.messageId}',
        );
        final notif = _parseRemoteMessage(message);
        _foregroundNotificationController.add(notif);

        // On Android, show local notification to trigger the banner manually
        if (Platform.isAndroid) {
          final notification = message.notification;
          final android = message.notification?.android;

          if (notification != null) {
            _localNotificationsPlugin.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                ),
              ),
              payload: jsonEncode(notif.toJson()),
            );
          }
        }
      });

      // Handle background/terminated message click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
          '[PushNotificationService] Background message clicked: ${message.messageId}',
        );
        final notif = _parseRemoteMessage(message);
        _notificationOpenedController.add(notif);
      });

      // Handle initial message (terminated app click via FCM)
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        final notif = _parseRemoteMessage(initialMessage);
        _notificationOpenedController.add(notif);
      }

      // Handle initial message (terminated app click via local notifications)
      final notificationAppLaunchDetails = await _localNotificationsPlugin
          .getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails != null &&
          notificationAppLaunchDetails.didNotificationLaunchApp) {
        final payload =
            notificationAppLaunchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final jsonMap = jsonDecode(payload) as Map<String, dynamic>;
            _notificationOpenedController.add(
              NotificationModel.fromJson(jsonMap),
            );
          } catch (_) {
            _notificationOpenedController.add(
              _createFallbackNotification(payload),
            );
          }
        }
      }
    } catch (e) {
      print(
        '[PushNotificationService] Initialization error (falling back to mock): $e',
      );
      _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  NotificationModel _parseRemoteMessage(RemoteMessage message) {
    try {
      if (message.data.isNotEmpty && message.data.containsKey('type')) {
        return NotificationModel.fromJson(message.data);
      }
    } catch (_) {}

    return NotificationModel(
      id:
          message.data['id']?.toString() ??
          'push-${DateTime.now().millisecondsSinceEpoch}',
      patientId: message.data['patientId']?.toString() ?? '',
      type: NotificationType.fromString(message.data['type']?.toString()),
      message:
          message.notification?.body ??
          message.data['message']?.toString() ??
          '',
      metadata: message.data,
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel _createFallbackNotification(String id) {
    return NotificationModel(
      id: id,
      patientId: '',
      type: NotificationType.general,
      message: 'New Notification',
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

  void dispose() {
    _foregroundNotificationController.close();
    _notificationOpenedController.close();
  }
}
