import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_state.dart';
import '../models/notification_state.dart';
import '../widgets/challenge_comparison_dialog.dart';
import '../widgets/friends_dialog.dart';
import 'home_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Challenges & Scores'),
          actions: [
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Friends & Public ID',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const FriendsDialog(),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.flash_on), text: 'Current'),
              Tab(icon: Icon(Icons.history), text: 'Past'),
              Tab(icon: Icon(Icons.leaderboard), text: 'Head-to-Head'),
            ],
          ),
        ),
        body: Consumer<ChallengeState>(
          builder: (context, state, child) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildCurrentTab(context, state),
                _buildPastTab(context, state),
                _buildHeadToHeadTab(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- TAB 1: CURRENT CHALLENGES ---
  Widget _buildCurrentTab(BuildContext context, ChallengeState state) {
    final challenges = state.currentChallenges;

    if (challenges.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 16),
              const Text(
                'No Current Challenges',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'When friends send you a puzzle challenge, it will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => state.addMockIncomingChallenge(notificationState: context.read<NotificationState>()),
                icon: const Icon(Icons.add_task),
                label: const Text('Add Demo Challenge'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final chal = challenges[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueGrey.withValues(alpha: 0.15),
                  child: const Icon(Icons.psychology, color: Colors.blueGrey, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenged by ${chal.challengerName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 16, color: Colors.blueGrey),
                          Text(
                            'Puzzle: ${chal.puzzleHash}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          puzzleHash: chal.puzzleHash,
                          activeChallengeId: chal.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: PAST CHALLENGES ---
  Widget _buildPastTab(BuildContext context, ChallengeState state) {
    final challenges = state.pastChallenges;

    if (challenges.isEmpty) {
      return const Center(
        child: Text('No past challenges completed yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final chal = challenges[index];
        final currentUserId = state.currentUser.id;
        final isUserChallenger = chal.challengerId == currentUserId;
        final opponentName = isUserChallenger ? chal.challengeeName : chal.challengerName;

        String resultText;
        Color resultColor;
        if (chal.winnerId == 'tie') {
          resultText = 'TIE GAME';
          resultColor = Colors.orange;
        } else if (chal.winnerId == currentUserId) {
          resultText = 'YOU WON';
          resultColor = Colors.green;
        } else {
          resultText = 'LOST';
          resultColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                chal.winnerId == currentUserId ? Icons.emoji_events : Icons.history,
                color: resultColor,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('vs $opponentName', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: resultColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    resultText,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Puzzle: ${chal.puzzleHash} • ${chal.completedAt?.toString().substring(0, 10) ?? ''}'),
            ),
            trailing: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ChallengeComparisonDialog(challenge: chal),
                );
              },
              child: const Text('Compare'),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 3: HEAD TO HEAD SCORES ---
  Widget _buildHeadToHeadTab(BuildContext context, ChallengeState state) {
    final statsList = state.getHeadToHeadStats();

    if (statsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No Head-to-Head stats yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Add friends and complete challenges to view player vs player scores!',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const FriendsDialog(),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('View Friends List'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statsList.length,
      itemBuilder: (context, index) {
        final stats = statsList[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stats.friendName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(stats.friendPublicId, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${stats.totalGames} Games',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScorePill('Your Wins', '${stats.userWins}', Colors.green),
                    _buildScorePill('${stats.friendName} Wins', '${stats.friendWins}', Colors.red),
                    _buildScorePill('Ties', '${stats.ties}', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScorePill(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
