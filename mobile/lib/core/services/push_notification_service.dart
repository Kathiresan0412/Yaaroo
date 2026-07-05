import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import '../../firebase_options.dart';

/// Top-level handler for background/killed state FCM messages.
/// This runs in a separate isolate — no access to app state.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('[FCM] Background message: ${message.messageId}');

  final data = message.data;
  if (data['type'] == 'incoming_call') {
    // Show native incoming call screen even when app is killed
    await _showNativeIncomingCall(data);
  }
}

/// Shows the native Android/iOS incoming call UI using flutter_callkit_incoming.
/// Works even when the app is completely dead.
Future<void> _showNativeIncomingCall(Map<String, dynamic> data) async {
  final callId = data['callId']?.toString() ?? const Uuid().v4();
  final callerName = data['callerName']?.toString() ?? 'Someone';
  final callerPhoto = data['callerPhoto']?.toString() ?? '';
  final isVideo = data['isVideo'] == 'true' || data['isVideo'] == true;
  final matchId = data['matchId']?.toString() ?? '';

  final params = CallKitParams(
    id: callId,
    nameCaller: callerName,
    appName: 'YaaRo0',
    avatar: callerPhoto.isNotEmpty ? callerPhoto : null,
    handle: 'YaaRo0 ${isVideo ? "Video" : "Voice"} Call',
    type: isVideo ? 1 : 0, // 0 = voice, 1 = video
    textAccept: 'Accept',
    textDecline: 'Decline',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: true,
      subtitle: 'Missed call',
      callbackText: 'Call back',
    ),
    duration: 45000, // Ring for 45 seconds
    extra: <String, dynamic>{
      'callId': callId,
      'matchId': matchId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'isVideo': isVideo.toString(),
    },
    headers: <String, dynamic>{},
    android: const AndroidParams(
      isCustomNotification: false,
      isShowLogo: true,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0B141A',
      actionColor: '#00A884',
      textColor: '#FFFFFF',
      isShowFullLockedScreen: true,
    ),
    ios: const IOSParams(
      iconName: 'AppIcon',
      handleType: 'generic',
      supportsVideo: true,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: false,
      supportsHolding: false,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
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
  void Function(String token)? onTokenRefresh;

  /// Callback invoked when user taps a notification.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Callback invoked when an incoming call arrives in foreground.
  void Function(Map<String, dynamic> data)? onIncomingCall;

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
    }

    // Setup local notifications for foreground display
    await _setupLocalNotifications();

    // Get initial token
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

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

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

    // Handle incoming call — show native call UI even in foreground
    if (data['type'] == 'incoming_call') {
      debugPrint('[FCM] Incoming call received in foreground');
      // Show native incoming call screen
      _showNativeIncomingCall(data);
      // Also notify the CallService callback
      onIncomingCall?.call(data);
      return;
    }

    if (notification == null) return;

    // Show a local notification for non-call messages
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

  /// Subscribe to a topic.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
