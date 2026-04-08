import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../widgets/liquid_glass.dart';

class LeaderboardScreen extends StatefulWidget {
  final UserProfile profile;
  const LeaderboardScreen({super.key, required this.profile});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  int _selectedTab = 0; // 0=weekly, 1=monthly, 2=alltime
  late List<_LeaderEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _buildEntries();
  }

  void _buildEntries() {
    final userEntry = _LeaderEntry(
      name: widget.profile.name,
      avatar: widget.profile.name.isNotEmpty
          ? widget.profile.name[0].toUpperCase()
          : 'U',
      weeklySteps: widget.profile.totalSteps,
      weeklyKm: widget.profile.totalDistanceKm,
      streak: widget.profile.totalRuns,
      badge: '🏃',
      isUser: true,
    );

    final fake = fakeLeaderboard
        .map((e) => _LeaderEntry(
              name: e.name,
              avatar: e.avatar,
              weeklySteps: _adjustSteps(e.weeklySteps),
              weeklyKm: e.weeklyKm,
              streak: e.streak,
              badge: e.badge,
              isUser: false,
            ))
        .toList();

    final allEntries = [...fake, userEntry];
    allEntries.sort((a, b) => b.weeklySteps.compareTo(a.weeklySteps));
    _entries = allEntries;
  }

  int _adjustSteps(int base) {
    if (_selectedTab == 1) return (base * 4.2).round();
    if (_selectedTab == 2) return (base * 18).round();
    return base;
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
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
                _buildHeader(),
                _buildTabs(),
                _buildTopThree(),
                Expanded(child: _buildList()),
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
      painter: _LeaderBgPainter(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
          Column(
            children: [
              Text(
                'LEADERBOARD',
                style: GoogleFonts.barlow(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'MANLIER RUNNERS',
                style: GoogleFonts.rajdhani(
                  color: const Color(0xFFFF6B00).withOpacity(0.7),
                  fontSize: 10,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          const Spacer(),
          LiquidGlassCard(
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            child: const Icon(Icons.filter_list_rounded,
                color: Color(0xFFFF6B00), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = i;
                    _buildEntries();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == i
                        ? const Color(0xFFFF6B00)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTab == i
                          ? const Color(0xFFFF6B00)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    ['WEEKLY', 'MONTHLY', 'ALL TIME'][i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: _selectedTab == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    if (_entries.length < 3) return const SizedBox.shrink();
    final top3 = _entries.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place
            Expanded(child: _buildPodiumItem(top3[1], 2, 100)),
            const SizedBox(width: 8),
            // 1st place
            Expanded(child: _buildPodiumItem(top3[0], 1, 130)),
            const SizedBox(width: 8),
            // 3rd place
            Expanded(child: _buildPodiumItem(top3[2], 3, 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(_LeaderEntry entry, int rank, double height) {
    final colors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFCCC9C9),
      3: const Color(0xFFCD7F32),
    };
    final color = colors[rank]!;

    return AnimatedBuilder(
      animation: _entryController,
      builder: (_, child) {
        final delay = (rank - 1) * 0.2;
        final progress = (((_entryController.value - delay) / 0.6).clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(0, 20 * (1 - progress)),
          child: Opacity(opacity: progress, child: child),
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (rank == 1)
              Text('👑', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            CircleAvatar(
              backgroundColor: color.withOpacity(0.3),
              radius: 20,
              child: Text(
                entry.avatar,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.name.split(' ').first,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatSteps(entry.weeklySteps),
              style: GoogleFonts.barlow(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final remaining = _entries.skip(3).toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: remaining.length,
      itemBuilder: (ctx, i) {
        final entry = remaining[i];
        final rank = i + 4;
        return AnimatedBuilder(
          animation: _entryController,
          builder: (_, child) {
            final delay = 0.3 + i * 0.08;
            final progress =
                ((_entryController.value - delay) / 0.5).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(30 * (1 - progress), 0),
              child: Opacity(opacity: progress, child: child),
            );
          },
          child: _buildLeaderRow(entry, rank),
        );
      },
    );
  }

  Widget _buildLeaderRow(_LeaderEntry entry, int rank) {
    final isUser = entry.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LiquidGlassCard(
        tintColor: isUser ? const Color(0xFFFF6B00) : const Color(0xFF1A1A1A),
        tintOpacity: isUser ? 0.15 : 0.05,
        border: isUser
            ? Border.all(color: const Color(0xFFFF6B00).withOpacity(0.4))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                style: GoogleFonts.barlow(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Avatar
            CircleAvatar(
              backgroundColor: isUser
                  ? const Color(0xFFFF6B00).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              radius: 18,
              child: Text(
                entry.avatar,
                style: TextStyle(
                  color: isUser ? const Color(0xFFFF6B00) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.name,
                        style: GoogleFonts.barlow(
                          color: isUser
                              ? Colors.white
                              : Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'YOU',
                            style: GoogleFonts.rajdhani(
                              color: const Color(0xFFFF6B00),
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '🔥 ${entry.streak}d streak',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatSteps(entry.weeklySteps),
                  style: GoogleFonts.barlow(
                    color: isUser
                        ? const Color(0xFFFF6B00)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${entry.weeklyKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(entry.badge, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000000) return '${(steps / 1000000).toStringAsFixed(1)}M';
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}k';
    return steps.toString();
  }
}

class _LeaderEntry {
  final String name;
  final String avatar;
  final int weeklySteps;
  final double weeklyKm;
  final int streak;
  final String badge;
  final bool isUser;

  _LeaderEntry({
    required this.name,
    required this.avatar,
    required this.weeklySteps,
    required this.weeklyKm,
    required this.streak,
    required this.badge,
    required this.isUser,
  });
}

class _LeaderBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.5, 80), 200, p1);
  }

  @override
  bool shouldRepaint(_) => false;
}
