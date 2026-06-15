import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../features/chat/presentation/incoming_call_screen.dart';
import '../../features/chat/presentation/zego_call_screen.dart';

/// Singleton service that listens for incoming call socket events and
/// shows the incoming call UI regardless of which screen the user is on.
class CallService {
  CallService._();
  static final CallService instance = CallService._();

  io.Socket? _socket;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentUserId;
  String? _currentUserName;

  /// Must be called once with the navigator key from MaterialApp.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Set the current user info so we can pass it to ZegoCallScreen.
  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  /// Attach to an existing socket to listen for incoming call events.
  void attachSocket(io.Socket socket) {
    // Remove old listeners if re-attaching
    _socket?.off('incoming_call');
    _socket?.off('call_ended');
    _socket?.off('call_rejected');

    _socket = socket;

    _socket!.on('incoming_call', (data) {
      if (data is! Map) return;
      final callId = data['callId']?.toString() ?? '';
      final matchId = data['matchId']?.toString() ?? '';
      final callerName = data['callerName']?.toString() ?? 'Someone';
      final callerPhoto = data['callerPhoto']?.toString();
      final isVideo = data['isVideo'] == true;
      final callerId = data['callerId']?.toString() ?? '';

      _showIncomingCall(
        callId: callId,
        matchId: matchId,
        callerId: callerId,
        callerName: callerName,
        callerPhoto: callerPhoto,
        isVideo: isVideo,
      );
    });

    _socket!.on('call_ended', (data) {
      // If we're on the incoming call screen, pop it
      // This handles the case where the caller hangs up before we answer
    });
  }

  /// Detach from the socket (e.g., on logout).
  void detach() {
    _socket?.off('incoming_call');
    _socket?.off('call_ended');
    _socket?.off('call_rejected');
    _socket = null;
    _currentUserId = null;
    _currentUserName = null;
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

  void _showIncomingCall({
    required String callId,
    required String matchId,
    required String callerId,
    required String callerName,
    String? callerPhoto,
    required bool isVideo,
  }) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(
          callId: callId,
          matchId: matchId,
          callerName: callerName,
          callerPhoto: callerPhoto,
          isVideo: isVideo,
          onAccept: () {
            // Notify the caller we accepted
            sendCallAccept(matchId, callId);

            // Navigate to the Zego call screen
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
          },
          onReject: () {
            sendCallReject(matchId, callId);
          },
        ),
      ),
    );
  }
}
