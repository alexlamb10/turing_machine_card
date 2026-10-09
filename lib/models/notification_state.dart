import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_model.dart';

class NotificationState extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  AppNotification? _activeToast;
  RealtimeChannel? _requestsChannel;
  RealtimeChannel? _challengesChannel;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  AppNotification? get activeToast => _activeToast;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationState() {
    _loadFromLocal();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('app_notifications') ?? [];
    _notifications = rawList.map((e) => AppNotification.fromJson(jsonDecode(e))).toList();
    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _notifications.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('app_notifications', rawList);
  }

  void dismissToast() {
    _activeToast = null;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _saveToLocal();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _saveToLocal();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _activeToast = null;
    _saveToLocal();
    notifyListeners();
  }

  void addNotification({
    required NotificationType type,
    required String title,
    required String message,
    String? targetPuzzleHash,
    String? relatedId,
  }) {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      type: type,
      title: title,
      message: message,
      targetPuzzleHash: targetPuzzleHash,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _activeToast = notification;
    _saveToLocal();
    notifyListeners();
  }

  // Helper trigger methods
  void notifyFriendRequestReceived({required String senderName, required String requestId}) {
    addNotification(
      type: NotificationType.friendRequest,
      title: 'New Friend Request',
      message: '$senderName sent you a friend request!',
      relatedId: requestId,
    );
  }

  void notifyFriendRequestAccepted({required String friendName}) {
    addNotification(
      type: NotificationType.friendAccepted,
      title: 'Friend Request Accepted',
      message: '$friendName accepted your friend request!',
    );
  }

  void notifyNewChallengeReceived({
    required String challengerName,
    required String puzzleHash,
    required String challengeId,
  }) {
    addNotification(
      type: NotificationType.newChallenge,
      title: 'New Puzzle Challenge!',
      message: '$challengerName challenged you to puzzle $puzzleHash.',
      targetPuzzleHash: puzzleHash,
      relatedId: challengeId,
    );
  }

  void notifyChallengeCompleted({
    required String challengeeName,
    required String puzzleHash,
    required String challengeId,
  }) {
    addNotification(
      type: NotificationType.challengeCompleted,
      title: 'Challenge Finished!',
      message: '$challengeeName finished your challenge on puzzle $puzzleHash. See who won!',
      targetPuzzleHash: puzzleHash,
      relatedId: challengeId,
    );
  }

  /// Sets up Supabase Realtime listeners for incoming changes if logged in
  void setupRealtimeListeners(String currentUserId) {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null || currentUserId.isEmpty) return;

      _requestsChannel?.unsubscribe();
      _challengesChannel?.unsubscribe();

      _requestsChannel = client.channel('public:friend_requests:$currentUserId');
      _requestsChannel?.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'friend_requests',
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord.isNotEmpty) {
            if (newRecord['to_user_id'] == currentUserId && payload.eventType == PostgresChangeEvent.insert) {
              notifyFriendRequestReceived(
                senderName: newRecord['from_user_name'] ?? 'Someone',
                requestId: newRecord['id'] ?? '',
              );
            } else if (newRecord['from_user_id'] == currentUserId &&
                newRecord['status'] == 'accepted' &&
                payload.eventType == PostgresChangeEvent.update) {
              notifyFriendRequestAccepted(
                friendName: newRecord['to_public_id'] ?? 'Your friend',
              );
            }
          }
        },
      ).subscribe();

      _challengesChannel = client.channel('public:challenges:$currentUserId');
      _challengesChannel?.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'challenges',
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord.isNotEmpty) {
            if (newRecord['challengee_id'] == currentUserId && payload.eventType == PostgresChangeEvent.insert) {
              notifyNewChallengeReceived(
                challengerName: newRecord['challenger_name'] ?? 'A friend',
                puzzleHash: newRecord['puzzle_hash'] ?? 'Unknown',
                challengeId: newRecord['id'] ?? '',
              );
            } else if (newRecord['challenger_id'] == currentUserId &&
                newRecord['status'] == 'completed' &&
                payload.eventType == PostgresChangeEvent.update) {
              notifyChallengeCompleted(
                challengeeName: newRecord['challengee_name'] ?? 'A friend',
                puzzleHash: newRecord['puzzle_hash'] ?? 'Unknown',
                challengeId: newRecord['id'] ?? '',
              );
            }
          }
        },
      ).subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _requestsChannel?.unsubscribe();
    _challengesChannel?.unsubscribe();
    super.dispose();
  }
}
