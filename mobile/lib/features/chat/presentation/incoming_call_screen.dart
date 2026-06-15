import 'dart:async';
import 'package:flutter/material.dart';
import '../../../main.dart' show YaaroColors;

/// Full-screen incoming call UI with accept/reject buttons.
/// Shows caller info (name, photo) and plays a ringtone-style animation.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({
    required this.callId,
    required this.matchId,
    required this.callerName,
    required this.isVideo,
    this.callerPhoto,
    this.onAccept,
    this.onReject,
    super.key,
  });

  final String callId;
  final String matchId;
  final String callerName;
  final bool isVideo;
  final String? callerPhoto;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _autoRejectTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Auto-reject after 45 seconds if not answered
    _autoRejectTimer = Timer(const Duration(seconds: 45), () {
      if (mounted) {
        widget.onReject?.call();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoRejectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Pulse animation around avatar
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                final opacity = 1.0 - _pulseController.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: YaaroColors.rose.withValues(alpha: opacity),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    child!,
                  ],
                );
              },
              child: CircleAvatar(
                radius: 60,
                backgroundColor: YaaroColors.surface,
                backgroundImage:
                    widget.callerPhoto != null && widget.callerPhoto!.isNotEmpty
                        ? NetworkImage(widget.callerPhoto!)
                        : null,
                child: widget.callerPhoto == null || widget.callerPhoto!.isEmpty
                    ? Text(
                        widget.callerName.isNotEmpty
                            ? widget.callerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.callerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const Spacer(flex: 3),
            // Accept / Reject buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject
                  _CallActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onTap: () {
                      widget.onReject?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                  // Accept
                  _CallActionButton(
                    icon: widget.isVideo ? Icons.videocam : Icons.call,
                    color: Colors.green,
                    label: 'Accept',
                    onTap: () {
                      widget.onAccept?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
