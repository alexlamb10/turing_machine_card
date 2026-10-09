import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../models/challenge_state.dart';

class ChallengeComparisonDialog extends StatelessWidget {
  final Challenge challenge;

  const ChallengeComparisonDialog({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<ChallengeState>().currentUser.id;
    final isUserChallenger = challenge.challengerId == currentUserId;

    final String player1Name = isUserChallenger ? 'You (${challenge.challengerName})' : challenge.challengerName;
    final bool player1Won = challenge.challengerWon;
    final bool player1BeatMachine = challenge.challengerBeatMachine;
    final int player1Clues = challenge.challengerClues;
    final int player1Rounds = challenge.challengerRounds;

    final String player2Name = isUserChallenger
        ? challenge.challengeeName
        : 'You (${challenge.challengeeName})';
    final bool player2Won = challenge.challengeeWon ?? false;
    final bool player2BeatMachine = challenge.challengeeBeatMachine ?? false;
    final int player2Clues = challenge.challengeeClues ?? 0;
    final int player2Rounds = challenge.challengeeRounds ?? 1;

    String bannerText = "IT'S A TIE!";
    Color bannerColor = Colors.orange;
    IconData bannerIcon = Icons.balance;

    if (challenge.winnerId == 'tie') {
      bannerText = "IT'S A TIE!";
      bannerColor = Colors.orange;
      bannerIcon = Icons.balance;
    } else if (challenge.winnerId == currentUserId) {
      bannerText = "VICTORY!";
      bannerColor = Colors.green;
      bannerIcon = Icons.emoji_events;
    } else {
      final winnerName = challenge.winnerId == challenge.challengerId ? challenge.challengerName : challenge.challengeeName;
      bannerText = "$winnerName WON!";
      bannerColor = Colors.blueGrey;
      bannerIcon = Icons.military_tech;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Winner Banner Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: bannerColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(bannerIcon, color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    bannerText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                'Puzzle: ${challenge.puzzleHash}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ),
            const SizedBox(height: 16),

            // Side-by-Side Comparison Table / Row
            Row(
              children: [
                Expanded(
                  child: _buildPlayerCard(
                    context: context,
                    name: player1Name,
                    won: player1Won,
                    beatMachine: player1BeatMachine,
                    clues: player1Clues,
                    rounds: player1Rounds,
                    isWinner: challenge.winnerId == challenge.challengerId,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'VS',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlayerCard(
                    context: context,
                    name: player2Name,
                    won: player2Won,
                    beatMachine: player2BeatMachine,
                    clues: player2Clues,
                    rounds: player2Rounds,
                    isWinner: challenge.winnerId == challenge.challengeeId,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Winner is determined by total clues/guesses (fewer is better). Rounds serve as tiebreaker.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required BuildContext context,
    required String name,
    required bool won,
    required bool beatMachine,
    required int clues,
    required int rounds,
    required bool isWinner,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? Colors.green : Colors.grey.withValues(alpha: 0.3),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWinner) const Icon(Icons.star, color: Colors.amber, size: 18),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isWinner ? Colors.green[800] : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildStatRow('Solved:', won ? 'YES' : 'NO', won ? Colors.green : Colors.red),
          const SizedBox(height: 6),
          _buildStatRow('Beat Machine:', beatMachine ? 'YES' : 'NO', beatMachine ? Colors.blue : Colors.grey),
          const SizedBox(height: 6),
          _buildStatRow('Total Clues:', '$clues', Colors.blueGrey, bold: true),
          const SizedBox(height: 6),
          _buildStatRow('Total Rounds:', '$rounds', Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
