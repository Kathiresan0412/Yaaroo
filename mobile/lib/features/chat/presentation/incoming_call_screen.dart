import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/image_utils.dart';

/// WhatsApp-style full-screen incoming call UI.
/// Dark background, large circular caller photo in center,
/// caller name + call type at top, Decline / Accept / Message at bottom.
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideHintController;
  Timer? _autoRejectTimer;

  // Swipe up to accept
  double _swipeOffset = 0;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();

    // Immersive full-screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _slideHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Auto-reject after 45 seconds if not answered
    _autoRejectTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && !_accepted) {
        widget.onReject?.call();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulseController.dispose();
    _slideHintController.dispose();
    _autoRejectTimer?.cancel();
    super.dispose();
  }

  void _onAccept() {
    if (_accepted) return;
    _accepted = true;
    HapticFeedback.mediumImpact();
    widget.onAccept?.call();
    Navigator.of(context).pop();
  }

  void _onDecline() {
    HapticFeedback.mediumImpact();
    widget.onReject?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final avatarRadius = size.width * 0.22;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A), // WhatsApp dark bg
      body: Stack(
        children: [
          // Subtle background pattern (like WhatsApp doodles)
          Positioned.fill(
            child: CustomPaint(
              painter: _DoodleBackgroundPainter(
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Caller name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Call type indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isVideo ? Icons.videocam : Icons.call,
                      size: 16,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isVideo
                          ? 'YaaRo0 Video Call'
                          : 'YaaRo0 Voice Call',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Large circular avatar with pulse rings
                _buildPulsingAvatar(avatarRadius),

                const Spacer(),

                // Swipe-up hint arrows
                AnimatedBuilder(
                  animation: _slideHintController,
                  builder: (context, _) {
                    final offset = _slideHintController.value * 8;
                    return Column(
                      children: [
                        Transform.translate(
                          offset: Offset(0, -offset),
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 28,
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, -offset * 0.6),
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 28,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Bottom action buttons
                _buildBottomActions(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingAvatar(double radius) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring 1
            _buildPulseRing(radius + 30, _pulseController.value),
            // Outer pulse ring 2 (offset phase)
            _buildPulseRing(radius + 20, (_pulseController.value + 0.5) % 1.0),
            // Avatar
            child!,
          ],
        );
      },
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A884).withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipOval(
          child: _buildAvatarContent(radius),
        ),
      ),
    );
  }

  Widget _buildPulseRing(double size, double animValue) {
    final opacity = (1.0 - animValue) * 0.4;
    final scale = 1.0 + (animValue * 0.3);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size * 2,
        height: size * 2,
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

  Widget _buildAvatarContent(double radius) {
    if (widget.callerPhoto != null && widget.callerPhoto!.isNotEmpty) {
      return cachedImage(
        widget.callerPhoto,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        thumbWidth: (radius * 2).round(),
      );
    }
    return _buildInitialsAvatar(radius);
  }

  Widget _buildInitialsAvatar(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: const Color(0xFF2A3942),
      alignment: Alignment.center,
      child: Text(
        widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.7,
          color: Colors.white70,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decline button
          _ActionButton(
            icon: Icons.call_end_rounded,
            color: const Color(0xFFEA4335),
            label: 'Decline',
            onTap: _onDecline,
          ),

          // Accept button (swipe-up or tap)
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _swipeOffset += details.delta.dy;
                // Negative = swiping up
                if (_swipeOffset < -80) {
                  _onAccept();
                }
              });
            },
            onVerticalDragEnd: (_) {
              setState(() => _swipeOffset = 0);
            },
            child: _ActionButton(
              icon:
                  widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              color: const Color(0xFF00A884),
              label: 'Swipe up to accept',
              onTap: _onAccept,
              size: 72,
            ),
          ),

          // Message button (decline with message — placeholder)
          _ActionButton(
            icon: Icons.message_rounded,
            color: const Color(0xFF5B6B76),
            label: 'Message',
            onTap: _onDecline, // For now, just declines
          ),
        ],
      ),
    );
  }
}

/// Individual action button widget (circular icon + label below)
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.size = 60,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.45,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Paints subtle doodle-like background pattern similar to WhatsApp
class _DoodleBackgroundPainter extends CustomPainter {
  _DoodleBackgroundPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(42); // Fixed seed for consistent pattern
    final icons = [
      _drawPhone,
      _drawHeart,
      _drawStar,
      _drawCircle,
      _drawSquare,
      _drawTriangle,
    ];

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final iconIndex = random.nextInt(icons.length);
      final iconSize = 12.0 + random.nextDouble() * 8;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi * 2);
      icons[iconIndex](canvas, paint, iconSize);
      canvas.restore();
    }
  }

  void _drawPhone(Canvas canvas, Paint paint, double s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 0.5, height: s * 0.8),
        Radius.circular(s * 0.1),
      ),
      paint,
    );
  }

  void _drawHeart(Canvas canvas, Paint paint, double s) {
    final path = Path()
      ..moveTo(0, s * 0.2)
      ..cubicTo(-s * 0.4, -s * 0.3, -s * 0.4, s * 0.1, 0, s * 0.4)
      ..cubicTo(s * 0.4, s * 0.1, s * 0.4, -s * 0.3, 0, s * 0.2);
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Paint paint, double s) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * math.pi / 180;
      final point =
          Offset(math.cos(angle) * s * 0.3, math.sin(angle) * s * 0.3);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCircle(Canvas canvas, Paint paint, double s) {
    canvas.drawCircle(Offset.zero, s * 0.25, paint);
  }

  void _drawSquare(Canvas canvas, Paint paint, double s) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: s * 0.4, height: s * 0.4),
      paint,
    );
  }

  void _drawTriangle(Canvas canvas, Paint paint, double s) {
    final path = Path()
      ..moveTo(0, -s * 0.3)
      ..lineTo(s * 0.25, s * 0.15)
      ..lineTo(-s * 0.25, s * 0.15)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
