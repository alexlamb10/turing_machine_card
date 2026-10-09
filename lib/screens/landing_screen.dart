import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stats_state.dart';
import '../models/challenge_state.dart';
import '../widgets/friends_dialog.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'challenges_screen.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback? onSignOut;
  const LandingScreen({super.key, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final challengeState = context.watch<ChallengeState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turing Machine Companion'),
        actions: [
          // Challenges Button with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.flash_on),
                tooltip: 'Challenges & Scores',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChallengesScreen()),
                  );
                },
              ),
              if (challengeState.pendingBadgeCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${challengeState.pendingBadgeCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Friends & Public ID Button
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
          // History Button
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          // Sign Out Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
              onSignOut?.call();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<StatsState>(
            builder: (context, stats, child) {
              if (stats.isLoading) {
                return const CircularProgressIndicator();
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 16),
                  const Text(
                    'Turing Machine Companion',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Sharable ID subtitle
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const FriendsDialog(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 6),
                          Text(
                            'ID: ${challengeState.currentUser.publicId}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard('Wins', stats.wins, Colors.green),
                      _buildStatCard('Losses', stats.losses, Colors.red),
                      _buildStatCard('Beat Machine', stats.machineBeats, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Main Action Buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _promptPuzzleHash(context, isChallenge: false),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Research', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _promptPuzzleHash(context, isChallenge: true),
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Start Challenge', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          backgroundColor: Colors.amber[800],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sub Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChallengesScreen()),
                          );
                        },
                        icon: const Icon(Icons.flash_on),
                        label: Text('Challenges (${challengeState.currentChallenges.length})'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HistoryScreen()),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _promptPuzzleHash(BuildContext context, {required bool isChallenge}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isChallenge ? 'Start Challenge Puzzle' : 'Enter Puzzle Hash / Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. #1 (or #A12B)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hash = controller.text.trim();
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    puzzleHash: hash.isEmpty ? 'Unknown' : hash,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isChallenge ? Colors.amber[800] : Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
            child: Text(isChallenge ? 'Start Challenge' : 'Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            '$value',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
