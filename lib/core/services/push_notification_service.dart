import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

final pushNotificationServiceProvider = Provider((ref) => PushNotificationService());

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiClient _api = ApiClient();

  Future<void> init() async {
    // 1. Request permissions for iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return; // User declined
    }

    // 2. Initialize local notifications for foreground messages
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(settings: initSettings);

    // 3. Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/launcher_icon',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  /// Sends the FCM token to the backend
  Future<void> registerToken({String? phone, String? userId}) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web';

      await _api.post('/notifications/register-token', {
        'token': token,
        'phone': phone,
        'userId': userId,
        'platform': platform,
      });
    } catch (e) {
      // Fail silently, we don't want to break the app if FCM token registration fails
      debugPrint('Failed to register FCM token: $e');
    }
  }
}
