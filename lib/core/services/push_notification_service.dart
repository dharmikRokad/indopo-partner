import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/request_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[PushNotificationService] Background message received: ${message.messageId}');
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description: 'This channel is used for important notifications.', // description
  importance: Importance.max,
  playSound: true,
);

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  String? _fcmToken;
  final _foregroundNotificationController =
      StreamController<RequestModel>.broadcast();
  final _notificationOpenedController = StreamController<String>.broadcast();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? get fcmToken => _fcmToken;
  Stream<RequestModel> get foregroundNotificationStream =>
      _foregroundNotificationController.stream;
  Stream<String> get notificationOpenedStream =>
      _notificationOpenedController.stream;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      // Register background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications for Android foreground notifications banner
      if (Platform.isAndroid) {
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _notificationOpenedController.add(payload);
          }
        },
      );

      // Configure foreground presentation options for iOS
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
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
        _handleIncomingMessage(message);

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
              payload: message.data['id']?.toString(),
            );
          }
        }
      });

      // Handle background/terminated message click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
          '[PushNotificationService] Background message clicked: ${message.messageId}',
        );
        final requestId = message.data['id']?.toString() ?? '';
        _notificationOpenedController.add(requestId);
      });

      // Handle initial message (terminated app click via FCM)
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final requestId = initialMessage.data['id']?.toString() ?? '';
        _notificationOpenedController.add(requestId);
      }

      // Handle initial message (terminated app click via local notifications)
      final notificationAppLaunchDetails =
          await _localNotificationsPlugin.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails != null &&
          notificationAppLaunchDetails.didNotificationLaunchApp) {
        final payload = notificationAppLaunchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _notificationOpenedController.add(payload);
        }
      }
    } catch (e) {
      print(
        '[PushNotificationService] Initialization error (falling back to mock): $e',
      );
      // Mock fallback: always provide a token so login succeeded
      _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _handleIncomingMessage(RemoteMessage message) {
    try {
      final request = RequestModel.fromJson(message.data);
      _foregroundNotificationController.add(request);
    } catch (_) {
      // Create fallback model using title and body
      final fallbackRequest = RequestModel(
        id:
            message.data['id']?.toString() ??
            'push-${DateTime.now().millisecondsSinceEpoch}',
        patientName: message.notification?.title ?? 'Notification',
        patientAge: 30,
        patientGender: 'Other',
        patientContact: '',
        description: message.notification?.body ?? '',
        attachments: const [],
        timestamp: DateTime.now(),
        status: RequestStatus.newRequest,
      );
      _foregroundNotificationController.add(fallbackRequest);
    }
  }

  void dispose() {
    _foregroundNotificationController.close();
    _notificationOpenedController.close();
  }
}
