import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../main.dart' show YaaroColors, YaaroScope;

/// ZEGOCLOUD Call Screen — supports both video and voice calls.
///
/// Credentials are loaded from .env:
///   ZEGO_APP_ID=2125203085
///   ZEGO_APP_SIGN=81555dd053b5b6d0946803c1e4c7154e675b350d0c6ad9cd3d9394ff2856e605
class ZegoCallScreen extends StatelessWidget {
  const ZegoCallScreen({
    required this.callId,
    required this.userId,
    required this.userName,
    required this.isVideo,
    this.otherUserName,
    this.otherUserPhotoUrl,
    super.key,
  });

  /// Unique call ID — typically the matchId so both users join the same room
  final String callId;

  /// Current user's ID
  final String userId;

  /// Current user's display name
  final String userName;

  /// Whether this is a video call (true) or voice-only call (false)
  final bool isVideo;

  /// Other user's name (for display)
  final String? otherUserName;

  /// Other user's photo URL
  final String? otherUserPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final int appID = int.tryParse(dotenv.env['ZEGO_APP_ID'] ?? '') ?? 0;
    final String appSign = dotenv.env['ZEGO_APP_SIGN'] ?? '';

    if (appID == 0 || appSign.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: YaaroColors.rose),
                const SizedBox(height: 16),
                const Text(
                  'Call service not configured.\nPlease add ZEGO_APP_ID and ZEGO_APP_SIGN to your .env file.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YaaroColors.rose,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ZegoUIKitPrebuiltCall(
      appID: appID,
      appSign: appSign,
      userID: userId,
      userName: userName,
      callID: callId,
      config: isVideo
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
        ..topMenuBar.isVisible = true
        ..duration.isVisible = true,
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// Helper function to start a Zego call from the chat screen.
void startZegoCall(
  BuildContext context, {
  required String matchId,
  required String otherUserName,
  String? otherUserPhotoUrl,
  required bool isVideo,
}) {
  final api = YaaroScope.of(context);
  final currentUser = api.user;

  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to make calls.')),
    );
    return;
  }

  // Use matchId as callId so both users join the same room
  final callId = 'yaaro_call_$matchId';

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ZegoCallScreen(
        callId: callId,
        userId: currentUser.id,
        userName: currentUser.displayName,
        isVideo: isVideo,
        otherUserName: otherUserName,
        otherUserPhotoUrl: otherUserPhotoUrl,
      ),
    ),
  );
}
