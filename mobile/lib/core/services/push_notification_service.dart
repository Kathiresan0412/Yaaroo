import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

/// Top-level handler for background messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Manages Firebase Cloud Messaging setup, permissions, token retrieval,
/// and foreground notification display.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Callback invoked with the FCM token whenever it's refreshed.
  /// Hook this up to send the token to your backend.
  void Function(String token)? onTokenRefresh;

  /// Callback invoked when user taps a notification.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Initialize Firebase + FCM. Call once in main() after Firebase.initializeApp.
  Future<void> init() async {
    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
    } catch (e) {
      debugPrint('[FCM] Permission request failed: $e');
      // Continue — local notifications can still work without FCM permission on
      // devices missing Google Play Services.
    }

    // Setup local notifications for foreground display
    await _setupLocalNotifications();

    // Get initial token — this can fail on emulators/devices without
    // Google Play Services (MISSING_INSTANCEID_SERVICE).
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('[FCM] Token: $_fcmToken');
      if (_fcmToken != null) {
        onTokenRefresh?.call(_fcmToken!);
      }
    } catch (e) {
      debugPrint('[FCM] Token retrieval failed (missing Play Services?): $e');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      onTokenRefresh?.call(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('[FCM] getInitialMessage failed: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidChannel = AndroidNotificationChannel(
      'yaaro_default',
      'YaaRo0 Notifications',
      description: 'Notifications for matches, messages, and activity.',
      importance: Importance.high,
    );

    const androidCallChannel = AndroidNotificationChannel(
      'yaaro_calls',
      'YaaRo0 Calls',
      description: 'Incoming call notifications.',
      importance: Importance.max,
    );

    // Create the channels on Android
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.createNotificationChannel(androidCallChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    // Handle incoming call data messages — show the incoming call UI directly
    if (data['type'] == 'incoming_call') {
      final callerName = data['callerName']?.toString() ?? 'Someone';
      final isVideo = data['isVideo'] == 'true';

      // The socket event will typically arrive first and show the incoming call UI.
      // Here we show a high-priority notification as a fallback (background/killed state).
      _localNotifications.show(
        message.hashCode,
        notification?.title ??
            (isVideo ? 'Incoming Video Call 📹' : 'Incoming Voice Call 📞'),
        notification?.body ?? '$callerName is calling you',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'yaaro_calls',
            'YaaRo0 Calls',
            channelDescription: 'Incoming call notifications.',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: true,
            timeoutAfter: 45000,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: jsonEncode(data),
      );
      return;
    }

    if (notification == null) return;

    // Show a local notification so the user sees it in foreground
    _localNotifications.show(
      message.hashCode,
      notification.title ?? 'YaaRo0',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'yaaro_default',
          'YaaRo0 Notifications',
          channelDescription:
              'Notifications for matches, messages, and activity.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    onNotificationTap?.call(message.data);
  }

  /// Subscribe to a topic (e.g. 'matches', 'messages').
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
