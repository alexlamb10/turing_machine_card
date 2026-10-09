import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/notification_state.dart';
import '../models/challenge_state.dart';
import 'friends_dialog.dart';
import '../screens/challenges_screen.dart';

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final notifState = context.watch<NotificationState>();
    final chalState = context.read<ChallengeState>();
    final notifications = notifState.notifications;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    const Text(
                      'Notification Center',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (notifState.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          '${notifState.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),

            // Top action bar
            if (notifications.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => notifState.markAllAsRead(),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark all as read'),
                  ),
                  TextButton.icon(
                    onPressed: () => notifState.clearAll(),
                    icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                    label: const Text('Clear all', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),

            // Notifications List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No notifications yet.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  chalState.addMockIncomingFriendRequest(notificationState: notifState);
                                },
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('Test Friend Request'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  chalState.addMockIncomingChallenge(notificationState: notifState);
                                },
                                icon: const Icon(Icons.emoji_events, size: 16),
                                label: const Text('Test Challenge'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return ListTile(
                          tileColor: n.isRead ? Colors.transparent : Colors.blueGrey.withValues(alpha: 0.05),
                          leading: CircleAvatar(
                            backgroundColor: _getIconBgColor(n.type),
                            child: Icon(_getNotifIcon(n.type), color: Colors.white, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(n.message, style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(n.createdAt),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () {
                            notifState.markAsRead(n.id);
                            Navigator.pop(context);
                            _handleNotificationTap(context, n);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification n) {
    switch (n.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        showDialog(
          context: context,
          builder: (ctx) => const FriendsDialog(),
        );
        break;
      case NotificationType.newChallenge:
      case NotificationType.challengeCompleted:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChallengesScreen()),
        );
        break;
    }
  }

  Color _getIconBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Colors.orange;
      case NotificationType.friendAccepted:
        return Colors.green;
      case NotificationType.newChallenge:
        return Colors.indigo;
      case NotificationType.challengeCompleted:
        return Colors.teal;
    }
  }

  IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendAccepted:
        return Icons.check_circle;
      case NotificationType.newChallenge:
        return Icons.emoji_events;
      case NotificationType.challengeCompleted:
        return Icons.military_tech;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
