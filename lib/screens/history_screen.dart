import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stats_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
      ),
      body: Consumer<StatsState>(
        builder: (context, stats, child) {
          if (stats.history.isEmpty) {
            return const Center(
              child: Text(
                'No games recorded yet.\nStart research and finish a game to see history!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: stats.history.length,
            itemBuilder: (context, index) {
              final record = stats.history[index];
              
              Color badgeColor;
              String labelText;
              IconData iconData;

              switch (record.outcome) {
                case 'beat_machine':
                  badgeColor = Colors.blue;
                  labelText = 'Beat Machine!';
                  iconData = Icons.emoji_events;
                  break;
                case 'win':
                  badgeColor = Colors.green;
                  labelText = 'Win';
                  iconData = Icons.check_circle;
                  break;
                default:
                  badgeColor = Colors.red;
                  labelText = 'Loss';
                  iconData = Icons.cancel;
                  break;
              }

              final dt = record.playedAt.toLocal();
              final month = dt.month.toString().padLeft(2, '0');
              final day = dt.day.toString().padLeft(2, '0');
              final year = dt.year;
              final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
              final minute = dt.minute.toString().padLeft(2, '0');
              final period = dt.hour >= 12 ? 'PM' : 'AM';

              final dateStr = '$month/$day/$year $hour12:$minute $period';

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: badgeColor.withOpacity(0.2),
                    child: Icon(iconData, color: badgeColor),
                  ),
                  title: Text(
                    'Hash: ${record.puzzleHash}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(dateStr),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          labelText,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Delete Game',
                        onPressed: () => _confirmDelete(context, record.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String recordId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game?'),
        content: const Text('Are you sure you want to delete this game from your history? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              context.read<StatsState>().deleteRecord(recordId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Game deleted successfully.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
