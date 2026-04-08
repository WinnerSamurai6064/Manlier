import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../widgets/liquid_glass.dart';
import 'hub_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  final PageController _pageController = PageController();

  // User inputs
  final TextEditingController _nameController = TextEditingController();
  double _height = 175;
  String _bodySize = 'athletic';
  double _weight = 70;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_profile');
    if (userData != null && mounted) {
      final profile = UserProfile.fromMap(jsonDecode(userData));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HubScreen(profile: profile)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_page < 2) {
      setState(() => _page++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _slideController.reset();
      _slideController.forward();
    } else {
      _saveAndContinue();
    }
  }

  Future<void> _saveAndContinue() async {
    if (_nameController.text.trim().isEmpty) return;
    final profile = UserProfile(
      name: _nameController.text.trim(),
      height: _height,
      bodySize: _bodySize,
      weightKg: _weight,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toMap()));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => HubScreen(profile: profile),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProgress(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildNamePage(),
                      _buildBodyPage(),
                      _buildWeightPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _OnboardBgPainter(_page / 2),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 3,
              decoration: BoxDecoration(
                color: i <= _page
                    ? const Color(0xFFFF6B00)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNamePage() {
    return SlideTransition(
      position: _slideAnim,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text(
              'What do\nwe call you?',
              style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your name will appear on the leaderboard.',
              style: GoogleFonts.rajdhani(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            LiquidGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                style: GoogleFonts.barlow(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter name...',
                  hintStyle: GoogleFonts.barlow(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.person_outline,
                      color: const Color(0xFFFF6B00).withOpacity(0.7), size: 22),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _nextPage(),
              ),
            ),
            const Spacer(),
            _buildNextButton('Continue'),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPage() {
    return SlideTransition(
      position: _slideAnim,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text(
              'Your build?',
              style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Helps us calculate calories accurately.',
              style: GoogleFonts.rajdhani(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 40),

            // Height slider
            LiquidGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HEIGHT',
                      style: GoogleFonts.rajdhani(
                          color: const Color(0xFFFF6B00),
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_height.round()} cm',
                        style: GoogleFonts.barlow(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(_height / 30.48).toStringAsFixed(1)} ft',
                        style: GoogleFonts.rajdhani(
                            color: Colors.white.withOpacity(0.4), fontSize: 16),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFF6B00),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: const Color(0xFFFF6B00),
                      overlayColor: const Color(0xFFFF6B00).withOpacity(0.2),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _height,
                      min: 140,
                      max: 220,
                      onChanged: (v) => setState(() => _height = v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Body size
            Text('BODY TYPE',
                style: GoogleFonts.rajdhani(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 3)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final type in ['slim', 'athletic', 'heavy'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _bodySize = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _bodySize == type
                                ? const Color(0xFFFF6B00)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _bodySize == type
                                  ? const Color(0xFFFF6B00)
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                type == 'slim'
                                    ? '🏃'
                                    : type == 'athletic'
                                        ? '💪'
                                        : '🔥',
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.toUpperCase(),
                                style: GoogleFonts.rajdhani(
                                  color: _bodySize == type
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            _buildNextButton('Continue'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightPage() {
    return SlideTransition(
      position: _slideAnim,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text(
              "Current\nweight?",
              style: GoogleFonts.barlow(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Used for calorie tracking — stays private.',
              style: GoogleFonts.rajdhani(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 48),

            // Weight display
            Center(
              child: Column(
                children: [
                  Text(
                    _weight.round().toString(),
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    'kg',
                    style: GoogleFonts.rajdhani(
                      color: const Color(0xFFFF6B00),
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Weight scroll-style slider
            LiquidGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('40 kg',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12)),
                      Text('${_weight.round()} kg',
                          style: const TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text('200 kg',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFF6B00),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: const Color(0xFFFF6B00),
                      overlayColor: const Color(0xFFFF6B00).withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _weight,
                      min: 40,
                      max: 200,
                      onChanged: (v) => setState(() => _weight = v),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            _buildNextButton("Let's Run"),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _nextPage,
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
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardBgPainter extends CustomPainter {
  final double progress;
  _OnboardBgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.15),
      180,
      p1,
    );
    final p2 = Paint()
      ..color = const Color(0xFFFF9A3C).withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      140,
      p2,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
