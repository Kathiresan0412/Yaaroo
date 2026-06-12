import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/models/match_document.dart';

/// Exception thrown when a call cannot be initiated.
class CallingException implements Exception {
  final String message;
  const CallingException(this.message);

  @override
  String toString() => 'CallingException: $message';
}

/// Abstract interface for the calling service.
///
/// Provides video and audio calling capabilities between matched users
/// using ZegoCloud's pre-built UI kit.
abstract class CallingService {
  /// Initializes ZegoCloud SDK with the provided [appId] and [appSign].
  ///
  /// Must be called before any call can be initiated.
  Future<void> initialize(String appId, String appSign);

  /// Starts a video call between the caller and the target user.
  ///
  /// The [callerId] and [callerName] identify the caller.
  /// The [targetUid] is the UID of the user being called.
  ///
  /// Throws [CallingException] if:
  /// - No Match_Document exists between the two users
  /// - The call fails to connect within 60 seconds
  Future<void> startVideoCall(
      String callerId, String callerName, String targetUid);

  /// Starts an audio call between the caller and the target user.
  ///
  /// The [callerId] and [callerName] identify the caller.
  /// The [targetUid] is the UID of the user being called.
  ///
  /// Throws [CallingException] if:
  /// - No Match_Document exists between the two users
  /// - The call fails to connect within 60 seconds
  Future<void> startAudioCall(
      String callerId, String callerName, String targetUid);
}

/// ZegoCloud-backed implementation of [CallingService].
///
/// Uses the ZegoCloud pre-built UI kit to handle WebRTC complexity.
/// Call IDs are generated deterministically using sorted UIDs joined
/// with an underscore (same format as match IDs).
class ZegoCallingService implements CallingService {
  final FirebaseFirestore _firestore;

  String? _appId;
  String? _appSign;
  bool _initialized = false;

  /// Connection timeout duration for call attempts.
  static const Duration connectionTimeout = Duration(seconds: 60);

  ZegoCallingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize(String appId, String appSign) async {
    _appId = appId;
    _appSign = appSign;
    _initialized = true;
  }

  @override
  Future<void> startVideoCall(
      String callerId, String callerName, String targetUid) async {
    await _initiateCall(
      callerId: callerId,
      callerName: callerName,
      targetUid: targetUid,
      isVideoCall: true,
    );
  }

  @override
  Future<void> startAudioCall(
      String callerId, String callerName, String targetUid) async {
    await _initiateCall(
      callerId: callerId,
      callerName: callerName,
      targetUid: targetUid,
      isVideoCall: false,
    );
  }

  /// Initiates a call after verifying prerequisites.
  ///
  /// 1. Checks SDK is initialized
  /// 2. Verifies a Match_Document exists between the users
  /// 3. Generates a deterministic call ID
  /// 4. Starts the call with a 60-second connection timeout
  Future<void> _initiateCall({
    required String callerId,
    required String callerName,
    required String targetUid,
    required bool isVideoCall,
  }) async {
    if (!_initialized || _appId == null || _appSign == null) {
      throw const CallingException(
        'Calling service not initialized. Call initialize() first.',
      );
    }

    // Verify match exists between users
    final matchExists = await _verifyMatchExists(callerId, targetUid);
    if (!matchExists) {
      throw const CallingException(
        'Calls are only available between matched users.',
      );
    }

    // Generate deterministic call ID using sorted UIDs
    final callId = _generateCallId(callerId, targetUid);

    // Start call with timeout
    try {
      await _startCall(
        callerId: callerId,
        callerName: callerName,
        targetUid: targetUid,
        callId: callId,
        isVideoCall: isVideoCall,
      ).timeout(
        connectionTimeout,
        onTimeout: () {
          throw const CallingException(
            'Call could not be completed. Connection timed out after 60 seconds.',
          );
        },
      );
    } on CallingException {
      rethrow;
    } on TimeoutException {
      throw const CallingException(
        'Call could not be completed. Connection timed out after 60 seconds.',
      );
    } catch (e) {
      throw CallingException(
        'Call could not be completed. Error: ${e.toString()}',
      );
    }
  }

  /// Verifies that a Match_Document exists between [callerId] and [targetUid].
  ///
  /// The match document ID is generated using the same deterministic format:
  /// sorted UIDs joined with an underscore.
  Future<bool> _verifyMatchExists(String callerId, String targetUid) async {
    final matchId = MatchDocument.generateMatchId(callerId, targetUid);
    final doc = await _firestore.collection('matches').doc(matchId).get();
    return doc.exists;
  }

  /// Generates a deterministic call ID from two UIDs.
  ///
  /// Sorts UIDs alphabetically and joins with underscore.
  /// This ensures both participants generate the same call ID.
  String _generateCallId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }

  /// Starts a ZegoCloud call using the pre-built call invitation service.
  ///
  /// NOTE: ZegoCloud SDK is temporarily disabled due to package version
  /// incompatibilities. This method is a stub that always succeeds.
  /// Re-enable when ZegoCloud publishes compatible package versions.
  Future<void> _startCall({
    required String callerId,
    required String callerName,
    required String targetUid,
    required String callId,
    required bool isVideoCall,
  }) async {
    // TODO: Re-enable when ZegoCloud packages are compatible
    // For now, throw an exception indicating the feature is temporarily unavailable
    throw const CallingException(
      'Video/audio calling is temporarily unavailable. Please try again later.',
    );
  }

  /// Initializes the call invitation service for the current user.
  ///
  /// NOTE: ZegoCloud SDK is temporarily disabled.
  Future<void> initUserForCalls({
    required String userId,
    required String userName,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (!_initialized || _appId == null || _appSign == null) {
      throw const CallingException(
        'Calling service not initialized. Call initialize() first.',
      );
    }
    // TODO: Re-enable ZegoCloud initialization
  }

  /// Uninitializes the ZegoCloud call invitation service.
  Future<void> uninitialize() async {
    // TODO: Re-enable ZegoCloud uninitialization
  }
}
