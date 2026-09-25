/// Model representing authenticated user data.
class UserModel {
  final String id;
  final String username;
  final String avatarId;
  final String? avatarUrl;
  final String token;
  final int classicHighscore;
  final String? email;
  final String? bio;
  final String authProvider;
  final int xpTotal;
  final int level;
  final int? nextLevelXp;
  final int honor;
  final dynamic dailyChallengeMedals;
  final int? coinBalance;

  UserModel({
    required this.id,
    required this.username,
    required this.avatarId,
    this.avatarUrl,
    required this.token,
    this.classicHighscore = 0,
    this.email,
    this.bio,
    this.authProvider = 'local',
    this.xpTotal = 0,
    this.level = 1,
    this.nextLevelXp,
    this.honor = 0,
    this.dailyChallengeMedals,
    this.coinBalance,
  });

  int get goldMedals {
    if (dailyChallengeMedals is Map) {
      return (dailyChallengeMedals['gold'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  int get silverMedals {
    if (dailyChallengeMedals is Map) {
      return (dailyChallengeMedals['silver'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  int get bronzeMedals {
    if (dailyChallengeMedals is Map) {
      return (dailyChallengeMedals['bronze'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  int get totalDailyMedals {
    if (dailyChallengeMedals is Map) {
      final m = dailyChallengeMedals as Map;
      return (m['missions_completed_total'] as num?)?.toInt() ??
          (m['completed_count'] as num?)?.toInt() ??
          (m['completed_missions'] as num?)?.toInt() ??
          (m['total_medals'] as num?)?.toInt() ??
          (((m['gold'] as num?)?.toInt() ?? 0) +
              ((m['silver'] as num?)?.toInt() ?? 0) +
              ((m['bronze'] as num?)?.toInt() ?? 0));
    }
    return 0;
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? avatarId,
    String? avatarUrl,
    String? token,
    int? classicHighscore,
    String? email,
    String? bio,
    String? authProvider,
    int? xpTotal,
    int? level,
    int? nextLevelXp,
    int? honor,
    dynamic dailyChallengeMedals,
    int? coinBalance,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      token: token ?? this.token,
      classicHighscore: classicHighscore ?? this.classicHighscore,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      authProvider: authProvider ?? this.authProvider,
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      honor: honor ?? this.honor,
      dailyChallengeMedals: dailyChallengeMedals ?? this.dailyChallengeMedals,
      coinBalance: coinBalance ?? this.coinBalance,
    );
  }

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackToken,
  }) {
    final rawXp =
        json['xp_total'] ??
        json['xpTotal'] ??
        json['total_xp'] ??
        json['xp'] ??
        0;
    final parsedXp = rawXp is num
        ? rawXp.toInt()
        : int.tryParse(rawXp.toString()) ?? 0;

    final rawLevel = json['level'];
    final parsedLevel = rawLevel is num
        ? rawLevel.toInt()
        : (rawLevel != null ? int.tryParse(rawLevel.toString()) : null);
    final finalLevel = parsedLevel ?? 1;

    final rawNextXp = json['next_level_xp'] ?? json['nextLevelXp'];
    final parsedNextXp = rawNextXp is num
        ? rawNextXp.toInt()
        : (rawNextXp != null ? int.tryParse(rawNextXp.toString()) : null);

    final rawClassicHs =
        json['classic_highscore'] ??
        json['classicHighscore'] ??
        json['highScore'] ??
        0;
    final parsedClassicHs = rawClassicHs is num
        ? rawClassicHs.toInt()
        : int.tryParse(rawClassicHs.toString()) ?? 0;

    final rawHonor = json['honor'] ?? 0;
    final parsedHonor = rawHonor is num
        ? rawHonor.toInt()
        : int.tryParse(rawHonor.toString()) ?? 0;

    final rawCoinBalance = json['coin_balance'] ?? json['coinBalance'];
    final parsedCoinBalance = rawCoinBalance is num
        ? rawCoinBalance.toInt()
        : (rawCoinBalance != null
              ? int.tryParse(rawCoinBalance.toString())
              : null);

    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username:
          json['username']?.toString() ?? json['name']?.toString() ?? 'Player',
      avatarId:
          json['avatar_id']?.toString() ??
          json['avatarId']?.toString() ??
          json['avatar']?.toString() ??
          'avatar_1',
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      token: json['token']?.toString() ?? fallbackToken ?? '',
      classicHighscore: parsedClassicHs,
      email: json['email']?.toString(),
      bio: json['bio']?.toString(),
      authProvider: json['auth_provider']?.toString() ?? 'local',
      xpTotal: parsedXp,
      level: finalLevel,
      nextLevelXp: parsedNextXp,
      honor: parsedHonor,
      dailyChallengeMedals:
          json['daily_challenge_medals'] ??
          (json['missions_completed_total'] != null
              ? {
                  'completed_count': json['missions_completed_total'],
                  'missions_completed_total': json['missions_completed_total'],
                }
              : (json['completed_missions'] != null
                    ? {'completed_count': json['completed_missions']}
                    : null)),
      coinBalance: parsedCoinBalance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarId': avatarId,
      'avatarUrl': avatarUrl,
      'token': token,
      'classicHighscore': classicHighscore,
      'email': email,
      'bio': bio,
      'authProvider': authProvider,
      'xp_total': xpTotal,
      'level': level,
      'next_level_xp': nextLevelXp,
      'honor': honor,
      'daily_challenge_medals': dailyChallengeMedals,
      'coin_balance': coinBalance,
    };
  }
}
