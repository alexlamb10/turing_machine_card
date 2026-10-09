class Challenge {
  final String id;
  final String puzzleHash;
  final String challengerId;
  final String challengerName;
  final bool challengerWon;
  final bool challengerBeatMachine;
  final int challengerClues;
  final int challengerRounds;

  final String challengeeId;
  final String challengeeName;
  final bool? challengeeWon;
  final bool? challengeeBeatMachine;
  final int? challengeeClues;
  final int? challengeeRounds;

  final String status; // 'pending', 'completed'
  final String? winnerId; // challengerId, challengeeId, or 'tie'
  final DateTime createdAt;
  final DateTime? completedAt;

  Challenge({
    required this.id,
    required this.puzzleHash,
    required this.challengerId,
    required this.challengerName,
    required this.challengerWon,
    required this.challengerBeatMachine,
    required this.challengerClues,
    required this.challengerRounds,
    required this.challengeeId,
    required this.challengeeName,
    this.challengeeWon,
    this.challengeeBeatMachine,
    this.challengeeClues,
    this.challengeeRounds,
    this.status = 'pending',
    this.winnerId,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'puzzleHash': puzzleHash,
        'challengerId': challengerId,
        'challengerName': challengerName,
        'challengerWon': challengerWon,
        'challengerBeatMachine': challengerBeatMachine,
        'challengerClues': challengerClues,
        'challengerRounds': challengerRounds,
        'challengeeId': challengeeId,
        'challengeeName': challengeeName,
        'challengeeWon': challengeeWon,
        'challengeeBeatMachine': challengeeBeatMachine,
        'challengeeClues': challengeeClues,
        'challengeeRounds': challengeeRounds,
        'status': status,
        'winnerId': winnerId,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] ?? '',
        puzzleHash: json['puzzleHash'] ?? json['puzzle_hash'] ?? 'Unknown',
        challengerId: json['challengerId'] ?? json['challenger_id'] ?? '',
        challengerName: json['challengerName'] ?? json['challenger_name'] ?? 'Challenger',
        challengerWon: json['challengerWon'] ?? json['challenger_won'] ?? false,
        challengerBeatMachine: json['challengerBeatMachine'] ?? json['challenger_beat_machine'] ?? false,
        challengerClues: json['challengerClues'] ?? json['challenger_clues'] ?? 0,
        challengerRounds: json['challengerRounds'] ?? json['challenger_rounds'] ?? 1,
        challengeeId: json['challengeeId'] ?? json['challengee_id'] ?? '',
        challengeeName: json['challengeeName'] ?? json['challengee_name'] ?? 'Challengee',
        challengeeWon: json['challengeeWon'] ?? json['challengee_won'],
        challengeeBeatMachine: json['challengeeBeatMachine'] ?? json['challengee_beat_machine'],
        challengeeClues: json['challengeeClues'] ?? json['challengee_clues'],
        challengeeRounds: json['challengeeRounds'] ?? json['challengee_rounds'],
        status: json['status'] ?? 'pending',
        winnerId: json['winnerId'] ?? json['winner_id'],
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
        completedAt: json['completedAt'] != null || json['completed_at'] != null
            ? DateTime.parse(json['completedAt'] ?? json['completed_at'])
            : null,
      );

  /// Computes the winner based on game metrics:
  /// 1. Was successful (win vs loss)
  /// 2. Total clues (fewer is better)
  /// 3. Total rounds (tiebreaker, fewer is better)
  static String computeWinner({
    required String challengerId,
    required bool challengerWon,
    required int challengerClues,
    required int challengerRounds,
    required String challengeeId,
    required bool challengeeWon,
    required int challengeeClues,
    required int challengeeRounds,
  }) {
    // 1. Success check
    if (challengerWon && !challengeeWon) return challengerId;
    if (!challengerWon && challengeeWon) return challengeeId;

    // 2. Clues check (fewer clues/guesses is better)
    if (challengerClues < challengeeClues) return challengerId;
    if (challengeeClues < challengerClues) return challengeeId;

    // 3. Rounds check (fewer rounds is tiebreaker)
    if (challengerRounds < challengeeRounds) return challengerId;
    if (challengeeRounds < challengerRounds) return challengeeId;

    // 4. Exact tie
    return 'tie';
  }
}

class HeadToHeadStats {
  final String friendUserId;
  final String friendName;
  final String friendPublicId;
  final int userWins;
  final int friendWins;
  final int ties;
  final int totalGames;

  HeadToHeadStats({
    required this.friendUserId,
    required this.friendName,
    required this.friendPublicId,
    required this.userWins,
    required this.friendWins,
    required this.ties,
    required this.totalGames,
  });
}
