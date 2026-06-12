import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification types supported by the app.
///
/// Each type maps to a specific screen destination when tapped.
class NotificationType {
  static const String match = 'match';
  static const String message = 'message';
  static const String superLike = 'super_like';

  /// All valid notification types.
  static const List<String> all = [match, message, superLike];
}

/// Returns the route destination for a given notification type.
///
/// - "match" → '/match_detail'
/// - "message" → '/chat'
/// - "super_like" → '/profile'
///
/// Returns `null` for unknown types.
String? routeForNotificationType(String type) {
  switch (type) {
    case NotificationType.match:
      return '/match_detail';
    case NotificationType.message:
      return '/chat';
    case NotificationType.superLike:
      return '/profile';
    default:
      return null;
  }
}

/// Abstract interface for push notification management.
///
/// Handles FCM token lifecycle, foreground notification display, and
/// notification tap routing.
abstract class NotificationService {
  /// Initializes FCM, requests permission, saves token to User_Document.
  ///
  /// If permission is denied, the app continues without push notifications.
  /// The [uid] is used to store the FCM token in the user's Firestore document.
  Future<void> initialize(String uid);

  /// Stream that emits new FCM tokens when they are refreshed.
  Stream<String> get onTokenRefresh;

  /// Displays a foreground notification using flutter_local_notifications.
  ///
  /// Called when a [RemoteMessage] is received while the app is in the
  /// foreground, since FCM does not natively display notifications in this state.
  Future<void> showForegroundNotification(RemoteMessage message);

  /// Handles notification tap routing based on the payload type.
  ///
  /// Routes to the appropriate screen:
  /// - "match" → match detail screen
  /// - "message" → chat screen
  /// - "super_like" → profile screen
  Future<void> handleNotificationTap(Map<String, dynamic> payload);
}

/// Callback type for handling notification taps.
///
/// The [route] is the destination path (e.g., '/chat'), and [payload] contains
/// the notification data including relevant IDs.
typedef NotificationTapCallback = void Function(
    String route, Map<String, dynamic> payload);

/// FCM and flutter_local_notifications backed implementation of [NotificationService].
///
/// This service:
/// 1. Requests notification permission on initialize
/// 2. Saves the FCM token to the user's Firestore document (`fcmToken` field)
/// 3. Listens for token refreshes and updates Firestore accordingly
/// 4. Shows foreground notifications via flutter_local_notifications
/// 5. Routes notification taps to the correct screen based on type
///
/// If notification permission is denied, the service gracefully continues
/// without blocking app functionality.
class FirebaseNotificationService implements NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;

  /// Optional callback invoked when a notification is tapped.
  ///
  /// Set this from your app's navigation layer to handle routing.
  NotificationTapCallback? onNotificationTap;

  /// The current user's UID, set during [initialize].
  /// Retained for token refresh operations.
  String? _currentUid;

  /// Stream controller for token refresh events.
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  /// Android notification channel configuration.
  static const String _channelId = 'yaaro_notifications';
  static const String _channelName = 'Yaaro Notifications';
  static const String _channelDescription =
      'Notifications for matches, messages, and super likes';

  FirebaseNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize(String uid) async {
    _currentUid = uid;

    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // If permission denied, allow app to continue without notifications
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint(
          'NotificationService: Permission denied, continuing without push notifications.');
      return;
    }

    // Initialize flutter_local_notifications for foreground display
    await _initializeLocalNotifications();

    // Get the current FCM token and save to User_Document
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(uid, token);
      }
    } catch (e) {
      debugPrint('NotificationService: Failed to get FCM token: $e');
    }

    // Listen for token refresh events
    _messaging.onTokenRefresh.listen((newToken) async {
      _tokenRefreshController.add(newToken);
      if (_currentUid != null) {
        await _saveTokenToFirestore(_currentUid!, newToken);
      }
    });

    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showForegroundNotification(message);
    });

    // Handle notification taps when app is opened from background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = message.data;
      handleNotificationTap(payload);
    });

    // Check if app was opened from a terminated state via notification tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage.data);
    }
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use the hashCode of the message ID for a unique notification ID
    final notificationId = message.messageId?.hashCode ?? 0;

    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      details,
      payload: _encodePayload(message.data),
    );
  }

  @override
  Future<void> handleNotificationTap(Map<String, dynamic> payload) async {
    final type = payload['type'] as String?;
    if (type == null) return;

    final route = routeForNotificationType(type);
    if (route == null) return;

    // Invoke the tap callback if one is registered
    onNotificationTap?.call(route, payload);
  }

  /// Initializes the flutter_local_notifications plugin.
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create the Android notification channel
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
    }
  }

  /// Handles taps on local notifications (foreground notifications).
  void _onLocalNotificationTap(NotificationResponse response) {
    final payloadString = response.payload;
    if (payloadString == null || payloadString.isEmpty) return;

    final payload = _decodePayload(payloadString);
    handleNotificationTap(payload);
  }

  /// Saves the FCM token to the user's Firestore document.
  Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    } catch (e) {
      debugPrint('NotificationService: Failed to save FCM token: $e');
    }
  }

  /// Encodes a payload map to a string for local notification storage.
  String _encodePayload(Map<String, dynamic> payload) {
    // Simple key=value encoding for the payload
    return payload.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decodes a payload string back to a map.
  Map<String, dynamic> _decodePayload(String payloadString) {
    final map = <String, dynamic>{};
    for (final part in payloadString.split('&')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        map[part.substring(0, idx)] = part.substring(idx + 1);
      }
    }
    return map;
  }

  /// Disposes of the token refresh stream controller.
  void dispose() {
    _tokenRefreshController.close();
  }
}
