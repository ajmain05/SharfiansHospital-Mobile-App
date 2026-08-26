import 'dart:io';
import 'dart:ui' show Color;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';

final pushNotificationServiceProvider = Provider((ref) => PushNotificationService());

// Brand accent used to tint Android notification icons — matches the app's
// primary blue everywhere else in the UI (and android/.../colors.xml's
// notification_color, used for background/killed-state notifications the
// native FCM SDK renders without ever going through this Dart code).
const _brandColor = Color(0xFF316BF3);

// One channel per notification category so a user can mute/prioritize them
// separately in system settings, instead of everything funneling into one
// channel at max importance. `category` in the FCM data payload picks one of
// these; anything missing/unrecognized (e.g. a manually composed admin
// notification, which has no category) falls back to `_generalChannel`.
const _paymentChannel = AndroidNotificationChannel(
  'payments_channel',
  'Payments',
  description: 'Deposit confirmations and payment due reminders.',
  importance: Importance.max,
);
const _eventChannel = AndroidNotificationChannel(
  'events_channel',
  'Events',
  description: 'Event registration updates, new events, and reminders.',
  importance: Importance.max,
);
const _generalChannel = AndroidNotificationChannel(
  'general_channel',
  'General',
  description: 'Announcements and other notifications.',
  importance: Importance.max,
);
const _channelsByCategory = {
  'payment': _paymentChannel,
  'event': _eventChannel,
};

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

    // 2. Initialize local notifications for foreground messages. Tapping one
    // routes via the link the admin attached (see _handleNotificationTap),
    // carried through as the plain-string payload since flutter_local_notifications
    // only supports a single string, not the full data map FCM gives the
    // other two tap paths below.
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) =>
          _handleNotificationTap(response.payload),
    );

    // Pre-register all 3 channels so they show up (and are mutable) in
    // system notification settings even before the first push of each kind
    // ever arrives.
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in [_paymentChannel, _eventChannel, _generalChannel]) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    // 3. Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Tapped from background, or app cold-started from a terminated state
    // by tapping a notification.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleNotificationTap(message.data['link']),
    );
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['link']);
    }

    // 5. Register this device unconditionally, even if nobody has logged in
    // yet — otherwise anyone who installs the app but never logs in (as an
    // investor or staff) is invisible to every notification audience.
    // loginWithPhone()/admin login attach an identity to this same token
    // afterwards; the backend upsert never blanks out an identity that's
    // already attached, so this can't undo an existing login.
    registerToken();
  }

  void _navigateHome() => appRouter.go('/');

  /// Routes a tapped notification's optional admin-attached link: an
  /// in-app path (relative, or absolute pointing at our own domain) is
  /// handled by the app's own router so it opens natively instead of in a
  /// browser tab; anything else is handed to the device's browser/relevant
  /// app. No link at all falls back to Home, same as before this existed.
  void _handleNotificationTap(String? link) {
    if (link == null || link.isEmpty) {
      _navigateHome();
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null) {
      _navigateHome();
      return;
    }
    const ownHosts = {'sharfianshospital.com', 'www.sharfianshospital.com'};
    if (uri.host.isEmpty || ownHosts.contains(uri.host)) {
      appRouter.go(uri.path.isEmpty ? '/' : '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}');
      return;
    }
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      // Background/killed-state notifications render `notification.imageUrl`
      // automatically via the native FCM SDK — this custom foreground path
      // bypasses that, so it needs to fetch and attach the image itself.
      StyleInformation? styleInformation;
      final imageUrl = android?.imageUrl;
      if (imageUrl != null) {
        try {
          final response = await Dio().get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          final bytes = Uint8List.fromList(response.data ?? const []);
          if (bytes.isNotEmpty) {
            styleInformation = BigPictureStyleInformation(
              ByteArrayAndroidBitmap(bytes),
              largeIcon: ByteArrayAndroidBitmap(bytes),
            );
          }
        } catch (e) {
          // Show the notification without the image rather than dropping it.
          debugPrint('Failed to download notification image: $e');
        }
      }

      final channel = _channelsByCategory[message.data['category']] ?? _generalChannel;

      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        payload: message.data['link'],
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@drawable/ic_notification',
            color: _brandColor,
            styleInformation: styleInformation,
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
