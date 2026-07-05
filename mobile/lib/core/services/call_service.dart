import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';
import '../../features/chat/presentation/zego_call_screen.dart';

/// Singleton service that handles all call signaling:
/// - Listens for incoming call socket events
/// - Listens for native CallKit accept/decline events
/// - Shows the native incoming call UI (via flutter_callkit_incoming)
/// - Navigates to ZegoCallScreen when call is accepted
class CallService {
  CallService._();
  static final CallService instance = CallService._();

  io.Socket? _socket;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentUserId;
  String? _currentUserName;

  /// Callback for when the callee accepts our outgoing call.
  VoidCallback? onCallAccepted;

  /// Callback for when the callee rejects our outgoing call.
  VoidCallback? onCallRejected;

  StreamSubscription? _callkitSubscription;

  /// Must be called once with the navigator key from MaterialApp.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Set the current user info so we can pass it to ZegoCallScreen.
  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  /// Initialize CallKit event listeners.
  /// Must be called once at app startup (after setNavigatorKey).
  void initCallKitListeners() {
    _callkitSubscription?.cancel();
    _callkitSubscription =
        FlutterCallkitIncoming.onEvent.listen(_onCallKitEvent);
  }

  /// Handle events from the native call UI (accept, decline, timeout, etc.)
  void _onCallKitEvent(CallEvent? event) {
    if (event == null) return;

    debugPrint('[CallKit] Event: ${event.event}, body: ${event.body}');

    switch (event.event) {
      case Event.actionCallAccept:
        _handleCallKitAccept(event.body);
        break;
      case Event.actionCallDecline:
        _handleCallKitDecline(event.body);
        break;
      case Event.actionCallTimeout:
        _handleCallKitDecline(event.body);
        break;
      case Event.actionCallEnded:
        // Call ended by the system or user
        break;
      default:
        break;
    }
  }

  void _handleCallKitAccept(Map<String, dynamic> body) {
    final extra = body['extra'] as Map<String, dynamic>? ?? body;
    final callId = extra['callId']?.toString() ?? body['id']?.toString() ?? '';
    final matchId = extra['matchId']?.toString() ?? '';
    final callerName = extra['callerName']?.toString() ?? 'Someone';
    final callerPhoto = extra['callerPhoto']?.toString();
    final isVideo = extra['isVideo'] == 'true' || extra['isVideo'] == true;

    // Notify the caller we accepted via socket
    sendCallAccept(matchId, callId);

    // Navigate to the Zego call screen
    final navigator = _navigatorKey?.currentState;
    if (navigator != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ZegoCallScreen(
            callId: callId,
            userId: _currentUserId ?? '',
            userName: _currentUserName ?? '',
            isVideo: isVideo,
            otherUserName: callerName,
            otherUserPhotoUrl: callerPhoto,
          ),
        ),
      );
    }
  }

  void _handleCallKitDecline(Map<String, dynamic> body) {
    final extra = body['extra'] as Map<String, dynamic>? ?? body;
    final callId = extra['callId']?.toString() ?? body['id']?.toString() ?? '';
    final matchId = extra['matchId']?.toString() ?? '';

    // Notify the caller we rejected
    sendCallReject(matchId, callId);
  }

  /// Attach to an existing socket to listen for incoming call events.
  void attachSocket(io.Socket socket) {
    // Remove old listeners if re-attaching
    _socket?.off('incoming_call');
    _socket?.off('call_ended');
    _socket?.off('call_rejected');
    _socket?.off('call_accepted');

    _socket = socket;

    _socket!.on('incoming_call', (data) {
      if (data is! Map) return;
      final callData = Map<String, dynamic>.from(data);
      // Show native incoming call screen
      _showNativeCallScreen(callData);
    });

    _socket!.on('call_ended', (data) {
      // Caller hung up before we answered — dismiss the native call screen
      final callId = (data is Map) ? data['callId']?.toString() : null;
      if (callId != null) {
        FlutterCallkitIncoming.endCall(callId);
      }
    });

    _socket!.on('call_accepted', (data) {
      // The callee accepted our outgoing call
      onCallAccepted?.call();
    });

    _socket!.on('call_rejected', (data) {
      // The callee rejected our outgoing call
      onCallRejected?.call();
    });
  }

  /// Detach from the socket (e.g., on logout).
  void detach() {
    _socket?.off('incoming_call');
    _socket?.off('call_ended');
    _socket?.off('call_rejected');
    _socket?.off('call_accepted');
    _socket = null;
    _currentUserId = null;
    _currentUserName = null;
    onCallAccepted = null;
    onCallRejected = null;
  }

  /// Handle incoming call from FCM data message.
  /// Shows the native call UI (CallKit will handle it).
  void handleFcmIncomingCall(Map<String, dynamic> data) {
    _showNativeCallScreen(data);
  }

  /// Show the native incoming call UI using flutter_callkit_incoming.
  Future<void> _showNativeCallScreen(Map<String, dynamic> data) async {
    final callId = data['callId']?.toString() ?? const Uuid().v4();
    final callerName = data['callerName']?.toString() ?? 'Someone';
    final callerPhoto = data['callerPhoto']?.toString() ?? '';
    final isVideo = data['isVideo'] == true || data['isVideo'] == 'true';
    final matchId = data['matchId']?.toString() ?? '';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'YaaRo0',
      avatar: callerPhoto.isNotEmpty ? callerPhoto : null,
      handle: 'YaaRo0 ${isVideo ? "Video" : "Voice"} Call',
      type: isVideo ? 1 : 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      duration: 45000,
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

  /// Send a call invitation through the socket.
  void sendCallInvite({
    required String matchId,
    required bool isVideo,
    required String callerName,
    String? callerPhoto,
  }) {
    _socket?.emit('call_invite', {
      'matchId': matchId,
      'isVideo': isVideo,
      'callerName': callerName,
      'callerPhoto': callerPhoto ?? '',
    });
  }

  /// Notify that the call was accepted.
  void sendCallAccept(String matchId, String callId) {
    _socket?.emit('call_accept', {
      'matchId': matchId,
      'callId': callId,
    });
  }

  /// Notify that the call was rejected.
  void sendCallReject(String matchId, String callId) {
    _socket?.emit('call_reject', {
      'matchId': matchId,
      'callId': callId,
    });
  }

  /// Notify that the call ended.
  void sendCallEnd(String matchId, String callId) {
    _socket?.emit('call_end', {
      'matchId': matchId,
      'callId': callId,
    });
  }

  /// End the native call UI programmatically.
  Future<void> endNativeCallScreen(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }

  /// Clean up subscriptions.
  void dispose() {
    _callkitSubscription?.cancel();
    _callkitSubscription = null;
  }
}
