import 'league_models.dart';
import 'league_tier_models.dart';

/// Aggregated response for the League screen (GET /league/dashboard).
class LeagueDashboardResponse {
  final CurrentLeague season;
  final LeagueCycleStatus? cycleStatus;
  final MyRankResponse? myStanding;
  final LeagueLeaderboardResponse? groupLeaderboard;

  LeagueDashboardResponse({
    required this.season,
    this.cycleStatus,
    this.myStanding,
    this.groupLeaderboard,
  });

  factory LeagueDashboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final seasonJson = data['season'] is Map
        ? Map<String, dynamic>.from(data['season'] as Map)
        : <String, dynamic>{};
    final season = CurrentLeague.fromJson(seasonJson);

    LeagueCycleStatus? cycleStatus;
    if (data['cycle_status'] != null && data['cycle_status'] is Map) {
      cycleStatus = LeagueCycleStatus.fromJson(
        Map<String, dynamic>.from(data['cycle_status'] as Map),
      );
    }

    MyRankResponse? myStanding;
    if (data['my_standing'] != null && data['my_standing'] is Map) {
      myStanding = MyRankResponse.fromJson(
        Map<String, dynamic>.from(data['my_standing'] as Map),
      );
    }

    LeagueLeaderboardResponse? groupLeaderboard;
    if (data['group_leaderboard'] != null) {
      if (data['group_leaderboard'] is Map) {
        groupLeaderboard = LeagueLeaderboardResponse.fromJson(
          Map<String, dynamic>.from(data['group_leaderboard'] as Map),
        );
      } else if (data['group_leaderboard'] is List) {
        final list = (data['group_leaderboard'] as List)
            .whereType<Map>()
            .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        groupLeaderboard = LeagueLeaderboardResponse(
          success: true,
          seasonNumber: season.seasonNumber,
          leagueStatus: season.status,
          top: list,
        );
      }
    }

    return LeagueDashboardResponse(
      season: season,
      cycleStatus: cycleStatus,
      myStanding: myStanding,
      groupLeaderboard: groupLeaderboard,
    );
  }
}
