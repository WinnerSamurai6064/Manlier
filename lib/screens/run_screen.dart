import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/user_profile.dart';
import '../widgets/liquid_glass.dart';

class RunScreen extends StatefulWidget {
  final UserProfile profile;
  const RunScreen({super.key, required this.profile});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with TickerProviderStateMixin {
  bool _isRunning = false;
  bool _isPaused = false;
  int _seconds = 0;
  int _steps = 0;
  double _speed = 0.0;
  Timer? _timer;
  StreamSubscription? _accelSub;

  // Step detection
  double _lastMag = 9.8;
  bool _stepUp = false;
  static const double _stepThreshold = 12.0;
  static const double _stepRelease = 10.0;

  late AnimationController _pulseController;
  late AnimationController _speedController;
  late Animation<double> _speedAnim;
  double _targetSpeed = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _speedController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _speedAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _speedController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSub?.cancel();
    _pulseController.dispose();
    _speedController.dispose();
    super.dispose();
  }

  void _startRun() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _startTimer();
    _startAccelerometer();
  }

  void _pauseRun() {
    setState(() => _isPaused = true);
    _timer?.cancel();
    _accelSub?.cancel();
  }

  void _resumeRun() {
    setState(() => _isPaused = false);
    _startTimer();
    _startAccelerometer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _startAccelerometer() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      final mag =
          math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _detectStep(mag);
      _updateSpeed(mag);
    });
  }

  void _detectStep(double mag) {
    if (mag > _stepThreshold && !_stepUp) {
      _stepUp = true;
      if (mounted) setState(() => _steps++);
    } else if (mag < _stepRelease) {
      _stepUp = false;
    }
    _lastMag = mag;
  }

  void _updateSpeed(double mag) {
    double newSpeed = 0;
    if (mag < 10.5) {
      newSpeed = 0;
    } else if (mag < 12) {
      newSpeed = 2.5;
    } else if (mag < 15) {
      newSpeed = 4.5;
    } else if (mag < 20) {
      newSpeed = 6.5;
    } else {
      newSpeed = 9.0;
    }

    if ((newSpeed - _targetSpeed).abs() > 0.5) {
      _targetSpeed = newSpeed;
      _speedAnim = Tween<double>(
        begin: _speed,
        end: _targetSpeed,
      ).animate(CurvedAnimation(parent: _speedController, curve: Curves.easeOut));
      _speedController
        ..reset()
        ..forward();
      _speedController.addListener(() {
        if (mounted) setState(() => _speed = _speedAnim.value);
      });
    }
  }

  void _stopRun() {
    _timer?.cancel();
    _accelSub?.cancel();

    final dist = (_steps * 0.75) / 1000;
    final cals =
        (_seconds / 3600) * 8 * widget.profile.weightKg;

    final updated = UserProfile(
      name: widget.profile.name,
      height: widget.profile.height,
      bodySize: widget.profile.bodySize,
      weightKg: widget.profile.weightKg,
      totalSteps: widget.profile.totalSteps + _steps,
      totalCalories: widget.profile.totalCalories + cals,
      totalRuns: widget.profile.totalRuns + 1,
      totalDistanceKm: widget.profile.totalDistanceKm + dist,
    );

    Navigator.pop(context, updated);
  }

  String get _formattedTime {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _distanceKm => (_steps * 0.75) / 1000;
  double get _paceMinKm =>
      _distanceKm > 0 ? (_seconds / 60) / _distanceKm : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: Stack(
        children: [
          _buildAnimatedBg(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildRunContent()),
                _buildControls(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBg() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _RunBgPainter(_pulseController.value, _isRunning),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: LiquidGlassCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          Text(
            'RUN TRACKER',
            style: GoogleFonts.rajdhani(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildRunContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big timer
          _buildBigTimer(),
          const SizedBox(height: 40),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${_distanceKm.toStringAsFixed(2)}',
                  'KM',
                  Icons.route_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  _steps.toString(),
                  'STEPS',
                  Icons.directions_walk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${_speed.toStringAsFixed(1)}',
                  'KM/H',
                  Icons.speed_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  _paceMinKm > 0
                      ? '${_paceMinKm.toStringAsFixed(1)}\'/km'
                      : '--',
                  'PACE',
                  Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calories
          LiquidGlassCard(
            tintColor: const Color(0xFFFF6B00),
            tintOpacity: 0.12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFFF6B00), size: 24),
                const SizedBox(width: 8),
                Text(
                  '${((_seconds / 3600) * 8 * widget.profile.weightKg).round()}',
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'kcal burned',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigTimer() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) {
            return Transform.scale(
              scale: _isRunning && !_isPaused
                  ? 1.0 + 0.015 * _pulseController.value
                  : 1.0,
              child: child,
            );
          },
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
            ).createShader(bounds),
            child: Text(
              _formattedTime,
              style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
          ),
        ),
        if (_isRunning)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _isPaused ? Colors.amber : const Color(0xFF4AFF4A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isPaused ? Colors.amber : const Color(0xFF4AFF4A))
                          .withOpacity(0.6),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isPaused ? 'PAUSED' : 'TRACKING',
                style: GoogleFonts.rajdhani(
                  color: _isPaused
                      ? Colors.amber
                      : const Color(0xFF4AFF4A),
                  fontSize: 11,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return LiquidGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B00).withOpacity(0.7), size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.barlow(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.rajdhani(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (!_isRunning) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GestureDetector(
          onTap: _startRun,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF9A3C)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
                const SizedBox(width: 8),
                Text(
                  'START',
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isPaused ? _resumeRun : _pauseRun,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.15)),
                ),
                child: Icon(
                  _isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _showStopDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF9A3C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stop_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      'FINISH',
                      style: GoogleFonts.barlow(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStopDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Finish Run?',
            style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: Text(
          'Save your run and return to hub.',
          style: GoogleFonts.rajdhani(
              color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue',
                style: GoogleFonts.rajdhani(
                    color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopRun();
            },
            child: Text('Save & Exit',
                style: GoogleFonts.rajdhani(
                    color: const Color(0xFFFF6B00),
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _RunBgPainter extends CustomPainter {
  final double pulse;
  final bool running;
  _RunBgPainter(this.pulse, this.running);

  @override
  void paint(Canvas canvas, Size size) {
    if (!running) return;
    final p = Paint()
      ..color = const Color(0xFFFF6B00)
          .withOpacity(0.04 + 0.02 * math.sin(pulse * math.pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.4),
      200 + 30 * math.sin(pulse * math.pi),
      p,
    );
  }

  @override
  bool shouldRepaint(_RunBgPainter old) => old.pulse != pulse;
}
