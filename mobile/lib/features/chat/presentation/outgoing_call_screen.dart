import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/image_utils.dart';

/// WhatsApp-style outgoing call screen shown to the caller while waiting
/// for the receiver to pick up. Large centered avatar, name at top,
/// status below, and cancel button at the bottom.
class OutgoingCallScreen extends StatefulWidget {
  const OutgoingCallScreen({
    required this.calleeName,
    required this.isVideo,
    this.calleePhoto,
    this.onCancel,
    this.onConnected,
    super.key,
  });

  final String calleeName;
  final bool isVideo;
  final String? calleePhoto;
  final VoidCallback? onCancel;

  /// Called when the callee accepts — parent should navigate to ZegoCallScreen.
  final VoidCallback? onConnected;

  @override
  State<OutgoingCallScreen> createState() => OutgoingCallScreenState();
}

class OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotController;
  Timer? _timeoutTimer;
  String _status = 'Ringing';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Timeout after 60 seconds
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() => _status = 'No answer');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulseController.dispose();
    _dotController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// Call this from outside when call is rejected
  void onCallRejected() {
    if (!mounted) return;
    setState(() => _status = 'Call declined');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// Call this from outside when call is accepted
  void onCallAccepted() {
    if (!mounted) return;
    setState(() => _status = 'Connecting...');
    widget.onConnected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final avatarSize = size.width * 0.45; // Large centered avatar

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Callee name — centered
            Text(
              widget.calleeName,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Status text with animated dots
            AnimatedBuilder(
              animation: _dotController,
              builder: (context, _) {
                final dots = '.' * ((_dotController.value * 3).floor() + 1);
                return Text(
                  _status == 'Ringing' ? 'Ringing$dots' : _status,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),

            const Spacer(flex: 2),

            // Large centered avatar with pulse animation
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse ring 1
                      _buildPulseRing(avatarSize + 40, _pulseController.value),
                      // Pulse ring 2 (offset)
                      _buildPulseRing(
                        avatarSize + 25,
                        (_pulseController.value + 0.5) % 1.0,
                      ),
                      // Avatar
                      child!,
                    ],
                  );
                },
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _buildAvatar(avatarSize),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Cancel button — centered at bottom
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onCancel?.call();
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEA4335),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFEA4335).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRing(double size, double animValue) {
    final opacity = (1.0 - animValue) * 0.3;
    final scale = 1.0 + (animValue * 0.2);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00A884).withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    if (widget.calleePhoto != null && widget.calleePhoto!.isNotEmpty) {
      return cachedImage(
        widget.calleePhoto,
        width: size,
        height: size,
        fit: BoxFit.cover,
        thumbWidth: size.round(),
      );
    }
    return _buildInitials(size);
  }

  Widget _buildInitials(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF2A3942),
      alignment: Alignment.center,
      child: Text(
        widget.calleeName.isNotEmpty ? widget.calleeName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.35,
          color: Colors.white70,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
