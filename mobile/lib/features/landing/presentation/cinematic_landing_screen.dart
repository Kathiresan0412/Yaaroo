import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium cinematic scroll-driven landing page for YaaroO.
/// Tells a visual story: silhouettes → walking together → café meeting → tea cup → CTA.
class CinematicLandingScreen extends StatefulWidget {
  const CinematicLandingScreen({
    required this.onLogin,
    required this.onCreateAccount,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;

  @override
  State<CinematicLandingScreen> createState() => _CinematicLandingScreenState();
}

class _CinematicLandingScreenState extends State<CinematicLandingScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  double _progress = 0.0; // 0.0 → 1.0

  late final AnimationController _steamController;
  late final AnimationController _pulseController;
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _steamController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent > 0) {
      setState(() {
        _progress = (_scrollController.offset / maxExtent).clamp(0.0, 1.0);
      });
    }
  }

  // Scene breakpoints
  static const _scene1End = 0.15;
  static const _scene2End = 0.35;
  static const _scene3End = 0.55;
  static const _scene4End = 0.70;
  static const _scene5End = 0.85;

  double _sceneProgress(double start, double end) {
    return ((_progress - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final s1 = _sceneProgress(0, _scene1End);
    final s2 = _sceneProgress(_scene1End, _scene2End);
    final s3 = _sceneProgress(_scene2End, _scene3End);
    final s4 = _sceneProgress(_scene3End, _scene4End);
    final s5 = _sceneProgress(_scene4End, _scene5End);
    final s6 = _sceneProgress(_scene5End, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          // Scrollable area (invisible — just for scroll physics)
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(height: size.height * 6),
            ),
          ),

          // Fixed visual viewport
          Positioned.fill(
            child: IgnorePointer(
              ignoring: s6 < 0.5,
              child: _buildVisualLayer(
                size: size,
                bottomPadding: bottomPadding,
                s1: s1,
                s2: s2,
                s3: s3,
                s4: s4,
                s5: s5,
                s6: s6,
              ),
            ),
          ),

          // Progress bar
          Positioned(
            right: 8,
            top: size.height * 0.3,
            bottom: size.height * 0.3,
            child: _buildProgressBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualLayer({
    required Size size,
    required double bottomPadding,
    required double s1,
    required double s2,
    required double s3,
    required double s4,
    required double s5,
    required double s6,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background layers
        _BackgroundLayer(s2: s2, s3: s3),

        // Scene 1: Hero text + silhouettes intro
        if (s1 < 1.0) _buildScene1(s1),

        // Scene 2 & 3: Characters walking + transition to real people
        _buildCharacterStage(s2: s2, s3: s3, s4: s4, s5: s5),

        // Scene 4: Conversation bubbles
        if (s4 > 0.2 && s5 < 0.8) _buildConversationHints(s4: s4, s5: s5),

        // Scene 5 & 6: Tea cup + CTA
        if (s5 > 0 || s6 > 0)
          _buildTeaCupAndCTA(s5: s5, s6: s6, bottomPadding: bottomPadding),

        // Header (always visible but fades)
        _buildHeader(s1),
      ],
    );
  }

  Widget _buildHeader(double s1) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: AnimatedBuilder(
            animation: _entryController,
            builder: (context, child) {
              return Opacity(
                opacity: _entryController.value * (1 - s1 * 0.3),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/brand/logo.png',
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2D79), Color(0xFFFF6D3B)],
                          ),
                        ),
                        child: const Icon(Icons.favorite,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFFF4D7A)],
                      ).createShader(bounds),
                      child: const Text(
                        'YaaroO',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScene1(double s1) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final entry = CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
        ).value;

        return Center(
          child: Opacity(
            opacity: entry * (1 - s1 * 2).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - entry) * 40 + s1 * -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Headline
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xB8FFFFFF)],
                      ).createShader(bounds),
                      child: const Text(
                        'Meet with trust,\nnot noise.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Subtitle
                    Text(
                      'SCROLL TO DISCOVER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Scroll arrow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _pulseController.value * 6),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.35),
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterStage({
    required double s2,
    required double s3,
    required double s4,
    required double s5,
  }) {
    final zoom = 1.0 + s2 * 0.1 + s3 * 0.15 + s4 * 0.1 + s5 * 0.3;
    final silhouetteOpacity = (1 - s3 * 2).clamp(0.0, 1.0);
    final realPeopleOpacity = (s3 * 1.5).clamp(0.0, 1.0);
    final surroundBlur = s5 * 10;

    // Characters walk toward each other
    final maleX = -120.0 + s2 * 120;
    final femaleX = 120.0 - s2 * 120;

    return Center(
      child: Transform.scale(
        scale: zoom,
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Silhouettes
              if (silhouetteOpacity > 0)
                Opacity(
                  opacity: silhouetteOpacity *
                      (s2 > 0
                          ? 1
                          : s2 == 0
                              ? 0.6
                              : 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(maleX, 0),
                        child: _Silhouette(isMale: true),
                      ),
                      const SizedBox(width: 60),
                      Transform.translate(
                        offset: Offset(femaleX, 0),
                        child: _Silhouette(isMale: false),
                      ),
                    ],
                  ),
                ),

              // Real people (café scene)
              if (realPeopleOpacity > 0)
                Opacity(
                  opacity: realPeopleOpacity,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: surroundBlur,
                      sigmaY: surroundBlur,
                    ),
                    child: _CafeScene(progress: s4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationHints({required double s4, required double s5}) {
    final opacity = ((s4 - 0.2) * 2).clamp(0.0, 1.0) * (1 - s5);
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.28,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChatBubble(isLeft: true, animController: _pulseController),
            const SizedBox(width: 32),
            _ChatBubble(isLeft: false, animController: _pulseController),
          ],
        ),
      ),
    );
  }

  Widget _buildTeaCupAndCTA({
    required double s5,
    required double s6,
    required double bottomPadding,
  }) {
    final teaOpacity = ((s5 * 1.5)).clamp(0.0, 1.0);
    final teaScale = 0.4 + s5 * 0.6;
    final ctaOpacity = s6;
    final ctaSlide = 40 - s6 * 40;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Tea cup
        Center(
          child: Opacity(
            opacity: teaOpacity,
            child: Transform.scale(
              scale: teaScale,
              child: _TeaCup(steamController: _steamController),
            ),
          ),
        ),

        // CTA Card
        if (ctaOpacity > 0)
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomPadding + 40,
            child: Opacity(
              opacity: ctaOpacity,
              child: Transform.translate(
                offset: Offset(0, ctaSlide),
                child: _CTACard(
                  onStart: widget.onLogin,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: FractionallySizedBox(
          heightFactor: _progress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF4D7A), Color(0xFF37E6D4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BACKGROUND LAYER
// ═══════════════════════════════════════════════════════

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.s2, required this.s3});

  final double s2;
  final double s3;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient: deep purple → navy
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1B0035), // Deep Purple
                Color(0xFF050018), // Dark Navy
                Color(0xFF0A0020),
              ],
            ),
          ),
        ),

        // Ambient glow (fades in as scroll progresses)
        Opacity(
          opacity: (s2 * 1.5).clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.3, 0.0),
                radius: 1.2,
                colors: [
                  Color(0x1AFF4D7A),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Café warmth overlay
        Opacity(
          opacity: s3.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, 0.2),
                radius: 0.8,
                colors: [
                  Color(0x22F7D9A8), // Warm café
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// SILHOUETTE
// ═══════════════════════════════════════════════════════

class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.isMale});

  final bool isMale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 130,
      child: CustomPaint(
        painter: _SilhouettePainter(isMale: isMale),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({required this.isMale});

  final bool isMale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = (isMale ? const Color(0xFF37E6D4) : const Color(0xFFFF4D7A))
          .withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final cx = size.width / 2;

    // Head
    canvas.drawCircle(Offset(cx, size.height * 0.12), 14, glowPaint);
    canvas.drawCircle(Offset(cx, size.height * 0.12), 14, paint);

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.42),
        width: isMale ? 26 : 30,
        height: 48,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(bodyRect, paint);

    // Legs
    final legWidth = 12.0;
    final legHeight = 44.0;
    final legTop = size.height * 0.62;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 14, legTop, legWidth, legHeight),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 2, legTop, legWidth, legHeight),
        const Radius.circular(6),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════
// CAFE SCENE
// ═══════════════════════════════════════════════════════

class _CafeScene extends StatelessWidget {
  const _CafeScene({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 200,
      child: CustomPaint(
        painter: _CafeScenePainter(progress: progress),
      ),
    );
  }
}

class _CafeScenePainter extends CustomPainter {
  _CafeScenePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Warm ambient glow
    canvas.drawCircle(
      Offset(cx, cy),
      80,
      Paint()
        ..color = const Color(0x18F7D9A8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    // Left person (male)
    _drawPerson(canvas, Offset(cx - 70, cy - 10), true);

    // Table
    final tablePaint = Paint()
      ..color = const Color(0xFF5C3A1E)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 30), width: 90, height: 8),
        const Radius.circular(4),
      ),
      tablePaint,
    );

    // Table leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 60), width: 8, height: 50),
        const Radius.circular(4),
      ),
      tablePaint..color = const Color(0xFF3D2510),
    );

    // Right person (female)
    _drawPerson(canvas, Offset(cx + 70, cy - 10), false);
  }

  void _drawPerson(Canvas canvas, Offset center, bool isMale) {
    final skinColor = isMale
        ? const Color(0xFF8B6914).withOpacity(0.7)
        : const Color(0xFF9B7030).withOpacity(0.7);
    final hairColor = const Color(0xFF1A0A00).withOpacity(0.8);

    final paint = Paint()..style = PaintingStyle.fill;

    // Head
    paint.color = skinColor;
    canvas.drawCircle(center + const Offset(0, -30), 16, paint);

    // Hair
    paint.color = hairColor;
    if (isMale) {
      canvas.drawArc(
        Rect.fromCircle(center: center + const Offset(0, -34), radius: 16),
        math.pi,
        math.pi,
        true,
        paint,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(0, -36), width: 36, height: 24),
        paint,
      );
    }

    // Body/shoulders
    paint.color = isMale
        ? const Color(0xFF2A1A4A).withOpacity(0.8) // Dark shirt
        : const Color(0xFF4A1030).withOpacity(0.8); // Warm top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: center + const Offset(0, 6), width: 30, height: 40),
        const Radius.circular(10),
      ),
      paint,
    );

    // Warm glow around person
    canvas.drawCircle(
      center,
      35,
      Paint()
        ..color = const Color(0x0CF7D9A8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  @override
  bool shouldRepaint(covariant _CafeScenePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ═══════════════════════════════════════════════════════
// CHAT BUBBLE
// ═══════════════════════════════════════════════════════

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.isLeft, required this.animController});

  final bool isLeft;
  final AnimationController animController;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isLeft ? 4 : 16),
        bottomRight: Radius.circular(isLeft ? 16 : 4),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isLeft ? 4 : 16),
              bottomRight: Radius.circular(isLeft ? 16 : 4),
            ),
          ),
          child: AnimatedBuilder(
            animation: animController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.15;
                  final t = ((animController.value + delay) % 1.0);
                  final scale = 0.6 + 0.4 * math.sin(t * math.pi);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TEA CUP
// ═══════════════════════════════════════════════════════

class _TeaCup extends StatelessWidget {
  const _TeaCup({required this.steamController});

  final AnimationController steamController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Warm glow behind cup
          Positioned(
            bottom: 20,
            child: Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF7D9A8).withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // Cup
          Positioned(
            bottom: 10,
            child: CustomPaint(
              size: const Size(100, 80),
              painter: _TeaCupPainter(),
            ),
          ),

          // Steam
          Positioned(
            bottom: 70,
            child: AnimatedBuilder(
              animation: steamController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (steamController.value + i * 0.3) % 1.0;
                    final y = -phase * 30;
                    final opacity = (1 - phase) * 0.3;
                    final scale = 1.0 + phase * 0.5;
                    return Transform.translate(
                      offset: Offset((i - 1) * 8.0, y),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeaCupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Saucer
    final saucerPaint = Paint()
      ..color = const Color(0xFFE8DDD0)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 6),
        width: size.width * 0.9,
        height: 14,
      ),
      saucerPaint,
    );

    // Cup body
    final cupPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5F0E8), Color(0xFFE8DDD0)],
      ).createShader(Rect.fromLTWH(0, 10, size.width, 50));

    final cupPath = Path()
      ..moveTo(cx - 30, 14)
      ..lineTo(cx - 24, size.height - 14)
      ..quadraticBezierTo(cx, size.height - 4, cx + 24, size.height - 14)
      ..lineTo(cx + 30, 14)
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Cup rim highlight
    canvas.drawLine(
      Offset(cx - 30, 14),
      Offset(cx + 30, 14),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFFE8DDD0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 38, 36), width: 20, height: 28),
      -math.pi / 2,
      math.pi,
      false,
      handlePaint,
    );

    // Tea liquid visible at top
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 18), width: 50, height: 10),
      Paint()..color = const Color(0xFF8B4513).withOpacity(0.4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════
// CTA CARD
// ═══════════════════════════════════════════════════════

class _CTACard extends StatelessWidget {
  const _CTACard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF0A0514).withOpacity(0.7),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: const Color(0xFFFF4D7A).withOpacity(0.05),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Every meaningful connection starts with a conversation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Verified profiles. Genuine people.\nReal connections.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              // CTA Button
              GestureDetector(
                onTap: onStart,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D7A), Color(0xFFFF2D6A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4D7A).withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF4D7A).withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Start Your Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
