class UserProfile {
  final String name;
  final double height; // cm
  final String bodySize; // slim, athletic, heavy
  double weightKg;
  int totalSteps;
  double totalCalories;
  int totalRuns;
  double totalDistanceKm;
  List<RunRecord> runHistory;

  UserProfile({
    required this.name,
    required this.height,
    required this.bodySize,
    this.weightKg = 70,
    this.totalSteps = 0,
    this.totalCalories = 0,
    this.totalRuns = 0,
    this.totalDistanceKm = 0,
    List<RunRecord>? runHistory,
  }) : runHistory = runHistory ?? [];

  double get bmi {
    final hm = height / 100;
    return weightKg / (hm * hm);
  }

  double get caloriesGoal {
    switch (bodySize) {
      case 'slim':
        return 1800;
      case 'heavy':
        return 2400;
      default:
        return 2100;
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'height': height,
    'bodySize': bodySize,
    'weightKg': weightKg,
    'totalSteps': totalSteps,
    'totalCalories': totalCalories,
    'totalRuns': totalRuns,
    'totalDistanceKm': totalDistanceKm,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    name: m['name'],
    height: m['height'],
    bodySize: m['bodySize'],
    weightKg: m['weightKg'] ?? 70,
    totalSteps: m['totalSteps'] ?? 0,
    totalCalories: m['totalCalories'] ?? 0.0,
    totalRuns: m['totalRuns'] ?? 0,
    totalDistanceKm: m['totalDistanceKm'] ?? 0.0,
  );
}

class RunRecord {
  final DateTime date;
  final int steps;
  final double distanceKm;
  final double calories;
  final int durationSeconds;

  RunRecord({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.calories,
    required this.durationSeconds,
  });

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// Fake leaderboard data
class LeaderboardEntry {
  final String name;
  final String avatar;
  final int weeklySteps;
  final double weeklyKm;
  final int streak;
  final String badge;

  const LeaderboardEntry({
    required this.name,
    required this.avatar,
    required this.weeklySteps,
    required this.weeklyKm,
    required this.streak,
    required this.badge,
  });
}

const List<LeaderboardEntry> fakeLeaderboard = [
  LeaderboardEntry(name: 'Marcus Reid', avatar: 'MR', weeklySteps: 87340, weeklyKm: 62.4, streak: 21, badge: '🔥'),
  LeaderboardEntry(name: 'James Okafor', avatar: 'JO', weeklySteps: 76200, weeklyKm: 54.1, streak: 14, badge: '⚡'),
  LeaderboardEntry(name: 'Tunde Alabi', avatar: 'TA', weeklySteps: 71100, weeklyKm: 50.7, streak: 9, badge: '💪'),
  LeaderboardEntry(name: 'Chris Mwangi', avatar: 'CM', weeklySteps: 65800, weeklyKm: 46.9, streak: 7, badge: '🏃'),
  LeaderboardEntry(name: 'David Chen', avatar: 'DC', weeklySteps: 59200, weeklyKm: 42.2, streak: 5, badge: '⭐'),
  LeaderboardEntry(name: 'Alex Torres', avatar: 'AT', weeklySteps: 52400, weeklyKm: 37.3, streak: 4, badge: '🎯'),
  LeaderboardEntry(name: 'Sam Adeyemi', avatar: 'SA', weeklySteps: 48100, weeklyKm: 34.2, streak: 3, badge: '🏅'),
  LeaderboardEntry(name: 'Ryan Osei', avatar: 'RO', weeklySteps: 41700, weeklyKm: 29.7, streak: 2, badge: '✨'),
];
