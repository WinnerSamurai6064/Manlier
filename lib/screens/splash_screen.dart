import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';
import '../widgets/liquid_glass.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _runnerController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _runnerAnim;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _runnerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0, 0.4, curve: Curves.easeIn)),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _runnerAnim = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _runnerController, curve: Curves.easeOut),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _runnerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const OnboardingScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _runnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          // Animated background orbs
          const _BackgroundOrbs(),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Runner silhouette
                SlideTransition(
                  position: _runnerAnim,
                  child: _RunnerSilhouette(),
                ),

                const SizedBox(height: 32),

                // Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: _LogoWidget(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline
                FadeTransition(
                  opacity: _textOpacity,
                  child: Text(
                    'BUILT FOR THE ROAD',
                    style: GoogleFonts.rajdhani(
                      color: const Color(0xFFFF6B00).withOpacity(0.7),
                      fontSize: 13,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // TREYTEK credit
                FadeTransition(
                  opacity: _textOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      children: [
                        Text(
                          'built by',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TREYTEK',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFFB347), Color(0xFFFF6B00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'MANLIER',
            style: GoogleFonts.barlow(
              color: Colors.white,
              fontSize: 62,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 200,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.transparent, Color(0xFFFF6B00), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class _RunnerSilhouette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _RunnerPainter(),
      ),
    );
  }
}

class _RunnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orangePaint = Paint()
      ..color = const Color(0xFFFF6B00)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow layer
    final glowPath = _buildRunnerPath(cx, cy, size);
    canvas.drawPath(glowPath, glowPaint);

    // Solid silhouette
    final runnerPath = _buildRunnerPath(cx, cy, size);
    canvas.drawPath(runnerPath, orangePaint);

    // Orange circle accent
    final circlePaint = Paint()
      ..color = const Color(0xFFFF9A3C).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), 72, circlePaint);

    final circlePaint2 = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 68, circlePaint2);
  }

  Path _buildRunnerPath(double cx, double cy, Size size) {
    final path = Path();
    final s = size.width / 160;

    // Head
    path.addOval(Rect.fromCenter(
      center: Offset(cx + 10 * s, cy - 55 * s),
      width: 20 * s,
      height: 20 * s,
    ));

    // Body
    path.moveTo(cx + 5 * s, cy - 44 * s);
    path.lineTo(cx - 5 * s, cy - 10 * s);
    path.lineTo(cx + 8 * s, cy - 10 * s);
    path.lineTo(cx + 15 * s, cy - 44 * s);
    path.close();

    // Left arm (forward)
    path.moveTo(cx, cy - 38 * s);
    path.quadraticBezierTo(cx - 20 * s, cy - 28 * s, cx - 28 * s, cy - 15 * s);
    path.lineTo(cx - 22 * s, cy - 12 * s);
    path.quadraticBezierTo(cx - 14 * s, cy - 24 * s, cx + 6 * s, cy - 34 * s);
    path.close();

    // Right arm (back)
    path.moveTo(cx + 12 * s, cy - 38 * s);
    path.quadraticBezierTo(cx + 28 * s, cy - 30 * s, cx + 32 * s, cy - 18 * s);
    path.lineTo(cx + 26 * s, cy - 16 * s);
    path.quadraticBezierTo(cx + 22 * s, cy - 27 * s, cx + 6 * s, cy - 35 * s);
    path.close();

    // Left leg (forward stride)
    path.moveTo(cx - 2 * s, cy - 10 * s);
    path.quadraticBezierTo(cx - 15 * s, cy + 15 * s, cx - 20 * s, cy + 40 * s);
    path.lineTo(cx - 12 * s, cy + 42 * s);
    path.quadraticBezierTo(cx - 8 * s, cy + 18 * s, cx + 6 * s, cy - 8 * s);
    path.close();

    // Right leg (back)
    path.moveTo(cx + 8 * s, cy - 10 * s);
    path.quadraticBezierTo(cx + 22 * s, cy + 10 * s, cx + 18 * s, cy + 38 * s);
    path.lineTo(cx + 26 * s, cy + 40 * s);
    path.quadraticBezierTo(cx + 30 * s, cy + 14 * s, cx + 16 * s, cy - 8 * s);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BackgroundOrbs extends StatefulWidget {
  const _BackgroundOrbs();

  @override
  State<_BackgroundOrbs> createState() => _BackgroundOrbsState();
}

class _BackgroundOrbsState extends State<_BackgroundOrbs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _OrbPainter(_controller.value),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.06 + 0.03 * sin(t * pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final paint2 = Paint()
      ..color = const Color(0xFFFF9A3C).withOpacity(0.04 + 0.02 * cos(t * pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      150 + 20 * sin(t * pi),
      paint1,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      120 + 15 * cos(t * pi),
      paint2,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
