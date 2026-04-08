import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../widgets/liquid_glass.dart';
import 'run_screen.dart';
import 'leaderboard_screen.dart';

class HubScreen extends StatefulWidget {
  final UserProfile profile;
  const HubScreen({super.key, required this.profile});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with TickerProviderStateMixin {
  late UserProfile _profile;
  late AnimationController _entryController;
  late List<Animation<double>> _cardAnims;
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cardAnims = List.generate(
      5,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(i * 0.12, 0.6 + i * 0.08, curve: Curves.easeOut),
        ),
      ),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _openRun() async {
    final result = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => RunScreen(profile: _profile),
      ),
    );
    if (result != null) {
      setState(() => _profile = result);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(_profile.toMap()));
    }
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(profile: _profile),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          _HubBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildDailyBalanceCard(),
                  _buildStatsRow(),
                  _buildRunButton(),
                  _buildActivityCard(),
                  _buildQuickStats(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _cardAnims[0],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: GoogleFonts.rajdhani(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _profile.name,
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _openLeaderboard,
                  child: LiquidGlassCard(
                    padding: const EdgeInsets.all(10),
                    borderRadius: 14,
                    child: const Icon(Icons.leaderboard_rounded,
                        color: Color(0xFFFF6B00), size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                LiquidGlassCard(
                  padding: const EdgeInsets.all(10),
                  borderRadius: 14,
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFFF6B00),
                    radius: 11,
                    child: Text(
                      _profile.name.isNotEmpty
                          ? _profile.name[0].toUpperCase()
                          : 'M',
                      style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBalanceCard() {
    final stepsProgress = (_profile.totalSteps / 10000).clamp(0.0, 1.0);
    final calProgress =
        (_profile.totalCalories / _profile.caloriesGoal).clamp(0.0, 1.0);
    final fitnessScore =
        ((stepsProgress + calProgress) / 2 * 100).round();

    return FadeTransition(
      opacity: _cardAnims[1],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: LiquidGlassCard(
          blur: 30,
          tintOpacity: 0.1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR DAILY BALANCE',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Steps · Calories · Fitness',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFF6B00).withOpacity(0.3)),
                    ),
                    child: Text(
                      'TODAY',
                      style: GoogleFonts.rajdhani(
                        color: const Color(0xFFFF6B00),
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleStatWidget(
                    value: _formatSteps(_profile.totalSteps),
                    label: 'STEPS',
                    progress: stepsProgress,
                    color: const Color(0xFFFF6B00),
                    size: 100,
                  ),
                  CircleStatWidget(
                    value: '${_profile.totalCalories.round()}',
                    label: 'KCAL',
                    progress: calProgress,
                    color: const Color(0xFFFF9A3C),
                    size: 100,
                  ),
                  CircleStatWidget(
                    value: '$fitnessScore%',
                    label: 'FITNESS',
                    progress: fitnessScore / 100,
                    color: const Color(0xFFFFB347),
                    size: 100,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMiniStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStats() {
    return Row(
      children: [
        _miniStatItem(
            Icons.directions_run, '${_profile.totalRuns}', 'runs'),
        _divider(),
        _miniStatItem(Icons.route_outlined,
            '${_profile.totalDistanceKm.toStringAsFixed(1)}', 'km total'),
        _divider(),
        _miniStatItem(Icons.local_fire_department_outlined,
            '${_profile.totalRuns * 3}', 'day streak'),
      ],
    );
  }

  Widget _miniStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFF6B00), size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.barlow(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: _cardAnims[2],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: LiquidGlassCard(
                tintColor: const Color(0xFFFF6B00),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.height,
                        color: const Color(0xFFFF6B00).withOpacity(0.7),
                        size: 18),
                    const SizedBox(height: 8),
                    Text(
                      '${_profile.height.round()} cm',
                      style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('HEIGHT',
                        style: GoogleFonts.rajdhani(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LiquidGlassCard(
                tintColor: const Color(0xFFFF9A3C),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.monitor_weight_outlined,
                        color: const Color(0xFFFF9A3C).withOpacity(0.7),
                        size: 18),
                    const SizedBox(height: 8),
                    Text(
                      '${_profile.weightKg.round()} kg',
                      style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('WEIGHT',
                        style: GoogleFonts.rajdhani(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LiquidGlassCard(
                tintColor: const Color(0xFFFFB347),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fitness_center,
                        color: const Color(0xFFFFB347).withOpacity(0.7),
                        size: 18),
                    const SizedBox(height: 8),
                    Text(
                      _profile.bodySize.toUpperCase(),
                      style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('BUILD',
                        style: GoogleFonts.rajdhani(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButton() {
    return FadeTransition(
      opacity: _cardAnims[3],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: GestureDetector(
          onTap: _openRun,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF9A3C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
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
                    color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(
                  'START A RUN',
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return FadeTransition(
      opacity: _cardAnims[4],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: LiquidGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WEEKLY ACTIVITY',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'This week',
                    style: GoogleFonts.rajdhani(
                      color: const Color(0xFFFF6B00),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeekBars(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekBars() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    final rng = math.Random(42);
    final values = List.generate(7, (i) {
      if (i > today) return 0.0;
      if (i == today && _profile.totalRuns > 0) return 0.7;
      return rng.nextDouble() * 0.8 + 0.1;
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final isToday = i == today;
        return Column(
          children: [
            Container(
              width: 28,
              height: 80 * values[i] + 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isToday
                      ? [const Color(0xFFFF6B00), const Color(0xFFFFB347)]
                      : [
                          const Color(0xFFFF6B00).withOpacity(0.3),
                          const Color(0xFFFF9A3C).withOpacity(0.3),
                        ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B00).withOpacity(0.4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              days[i],
              style: TextStyle(
                color: isToday
                    ? const Color(0xFFFF6B00)
                    : Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontWeight:
                    isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: LiquidGlassCard(
              tintColor: const Color(0xFFFF6B00),
              tintOpacity: 0.06,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏱', style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    _profile.totalRuns > 0 ? '32 min' : '--',
                    style: GoogleFonts.barlow(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text('AVG DURATION',
                      style: GoogleFonts.rajdhani(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LiquidGlassCard(
              tintColor: const Color(0xFFFF9A3C),
              tintOpacity: 0.06,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏅', style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    _profile.totalRuns > 0
                        ? '${(_profile.totalDistanceKm / math.max(_profile.totalRuns, 1)).toStringAsFixed(1)} km'
                        : '--',
                    style: GoogleFonts.barlow(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text('AVG RUN',
                      style: GoogleFonts.rajdhani(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFFF6B00).withOpacity(0.15),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.home_rounded, 'HUB', 0),
              _navItem(Icons.directions_run_rounded, 'RUN', 1, onTap: _openRun),
              _navItem(Icons.bar_chart_rounded, 'STATS', 2),
              _navItem(Icons.leaderboard_rounded, 'RANK', 3,
                  onTap: _openLeaderboard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index,
      {VoidCallback? onTap}) {
    final active = _bottomIndex == index;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _bottomIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFFF6B00).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: active
                  ? const Color(0xFFFF6B00)
                  : Colors.white.withOpacity(0.3),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: active
                  ? const Color(0xFFFF6B00)
                  : Colors.white.withOpacity(0.3),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}k';
    return steps.toString();
  }
}

class _HubBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _HubBgPainter(),
    );
  }
}

class _HubBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 200, p1);

    final p2 = Paint()
      ..color = const Color(0xFFFF9A3C).withOpacity(0.03)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 130);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.6), 180, p2);
  }

  @override
  bool shouldRepaint(_) => false;
}
