class XpReward {
  final int xpAwarded;
  final int xpTotal;
  final int level;
  final bool leveledUp;
  final int? nextLevelXp;

  XpReward({
    required this.xpAwarded,
    required this.xpTotal,
    required this.level,
    required this.leveledUp,
    this.nextLevelXp,
  });

  factory XpReward.fromJson(Map<String, dynamic> json) {
    final rawAwarded = json['xp_awarded'] ?? json['xp_gained'] ?? json['xp'] ?? 0;
    final rawTotal = json['xp_total'] ?? json['total_xp'] ?? json['xp'] ?? 0;
    final parsedAwarded = rawAwarded is num ? rawAwarded.toInt() : int.tryParse(rawAwarded.toString()) ?? 0;
    final parsedTotal = rawTotal is num ? rawTotal.toInt() : int.tryParse(rawTotal.toString()) ?? 0;

    final rawLevel = json['level'];
    final parsedLevel = rawLevel is num
        ? rawLevel.toInt()
        : (rawLevel != null ? int.tryParse(rawLevel.toString()) : null);
    final finalLevel = parsedLevel ?? 1;

    final rawNextXp = json['next_level_xp'] ?? json['nextLevelXp'];
    final parsedNextXp = rawNextXp is num
        ? rawNextXp.toInt()
        : (rawNextXp != null ? int.tryParse(rawNextXp.toString()) : null);

    return XpReward(
      xpAwarded: parsedAwarded,
      xpTotal: parsedTotal,
      level: finalLevel,
      leveledUp: json['leveled_up'] == true || json['leveled_up'] == 1 || json['level_up'] == true,
      nextLevelXp: parsedNextXp,
    );
  }

  Map<String, dynamic> toJson() => {
    'xp_awarded': xpAwarded,
    'xp_total': xpTotal,
    'level': level,
    'leveled_up': leveledUp,
    'next_level_xp': nextLevelXp,
  };
}
