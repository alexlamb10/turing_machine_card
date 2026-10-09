import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'friend.dart';
import 'challenge.dart';
import 'notification_state.dart';

class ChallengeState extends ChangeNotifier {
  UserProfile _currentUser = UserProfile(id: '', publicId: '', displayName: 'Player');
  List<Friendship> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];
  List<Challenge> _challenges = [];
  bool _isLoading = true;

  UserProfile get currentUser => _currentUser;
  List<Friendship> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get incomingRequests => List.unmodifiable(_incomingRequests.where((r) => r.status == 'pending'));
  List<FriendRequest> get outgoingRequests => List.unmodifiable(_outgoingRequests);
  List<Challenge> get challenges => List.unmodifiable(_challenges);
  bool get isLoading => _isLoading;

  List<Challenge> get currentChallenges =>
      _challenges.where((c) => c.challengeeId == _currentUser.id && c.status == 'pending').toList();

  List<Challenge> get pastChallenges =>
      _challenges.where((c) => c.status == 'completed' && (c.challengerId == _currentUser.id || c.challengeeId == _currentUser.id)).toList();

  int get pendingBadgeCount => currentChallenges.length + incomingRequests.length;

  ChallengeState() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    User? sbUser;
    try {
      sbUser = Supabase.instance.client.auth.currentUser;
    } catch (_) {}

    String userId = sbUser?.id ?? prefs.getString('local_user_id') ?? '';
    if (userId.isEmpty) {
      userId = 'usr_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      await prefs.setString('local_user_id', userId);
    }

    String publicId = prefs.getString('public_id') ?? '';
    if (publicId.isEmpty) {
      publicId = _generatePublicId();
      await prefs.setString('public_id', publicId);
    }

    String displayName = sbUser?.email?.split('@').first ?? prefs.getString('display_name') ?? 'Player_${publicId.substring(publicId.length - 4)}';

    _currentUser = UserProfile(
      id: userId,
      publicId: publicId,
      displayName: displayName,
    );

    await _loadFromLocal();
    await _syncFromSupabase();

    _isLoading = false;
    notifyListeners();
  }

  static String _generatePublicId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final code = List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
    return 'TM-$code';
  }

  Future<void> updateDisplayName(String name) async {
    if (name.trim().isEmpty) return;
    _currentUser = UserProfile(
      id: _currentUser.id,
      publicId: _currentUser.publicId,
      displayName: name.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', _currentUser.displayName);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('profiles').upsert({
          'id': _currentUser.id,
          'public_id': _currentUser.publicId,
          'display_name': _currentUser.displayName,
        });
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Friends
    final friendsRaw = prefs.getStringList('local_friends') ?? [];
    _friends = friendsRaw.map((e) => Friendship.fromJson(jsonDecode(e))).toList();

    // Load Friend Requests
    final incRaw = prefs.getStringList('local_incoming_requests') ?? [];
    _incomingRequests = incRaw.map((e) => FriendRequest.fromJson(jsonDecode(e))).toList();

    final outRaw = prefs.getStringList('local_outgoing_requests') ?? [];
    _outgoingRequests = outRaw.map((e) => FriendRequest.fromJson(jsonDecode(e))).toList();

    // Load Challenges
    final chalRaw = prefs.getStringList('local_challenges') ?? [];
    _challenges = chalRaw.map((e) => Challenge.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('local_friends', _friends.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setStringList('local_incoming_requests', _incomingRequests.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setStringList('local_outgoing_requests', _outgoingRequests.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setStringList('local_challenges', _challenges.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> _syncFromSupabase() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Sync Profile
      await client.from('profiles').upsert({
        'id': user.id,
        'public_id': _currentUser.publicId,
        'display_name': _currentUser.displayName,
      });

      // Sync Friendships
      final friendsRes = await client.from('friendships').select().or('user_id.eq.${user.id},friend_user_id.eq.${user.id}');
      _friends = (friendsRes as List).map((row) {
        final isUser = row['user_id'] == user.id;
        return Friendship(
          id: row['id'] ?? '',
          userId: user.id,
          friendUserId: isUser ? row['friend_user_id'] : row['user_id'],
          friendPublicId: isUser ? (row['friend_public_id'] ?? '') : (row['user_public_id'] ?? ''),
          friendName: isUser ? (row['friend_name'] ?? 'Friend') : (row['user_name'] ?? 'Friend'),
          createdAt: DateTime.parse(row['created_at'] ?? DateTime.now().toIso8601String()),
        );
      }).toList();

      // Sync Challenges
      final chalRes = await client.from('challenges').select().or('challenger_id.eq.${user.id},challengee_id.eq.${user.id}');
      _challenges = (chalRes as List).map((row) => Challenge.fromJson(row)).toList();
    } catch (_) {
      // Local mode fallback handles offline/failures
    }
  }

  // --- FRIEND REQUEST FLOW ---

  Future<bool> sendFriendRequest(String targetPublicId) async {
    final cleanId = targetPublicId.trim().toUpperCase();
    if (cleanId == _currentUser.publicId) {
      throw Exception("You cannot send a friend request to yourself.");
    }
    if (_friends.any((f) => f.friendPublicId.toUpperCase() == cleanId)) {
      throw Exception("You are already friends with this user.");
    }

    final reqId = 'req_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    String targetUserId = 'usr_remote_$cleanId';
    String targetName = 'User_$cleanId';

    // Check online user profile if possible
    try {
      final client = Supabase.instance.client;
      final profilesRes = await client.from('profiles').select().eq('public_id', cleanId).maybeSingle();
      if (profilesRes != null) {
        targetUserId = profilesRes['id'];
        targetName = profilesRes['display_name'] ?? targetName;
      }
    } catch (_) {}

    final request = FriendRequest(
      id: reqId,
      fromUserId: _currentUser.id,
      fromPublicId: _currentUser.publicId,
      fromUserName: _currentUser.displayName,
      toUserId: targetUserId,
      toPublicId: cleanId,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    _outgoingRequests.add(request);

    // Auto-accept in local/guest mock mode if target is local or for testing
    // Also save request
    await _saveToLocal();

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.from('friend_requests').insert({
          'id': request.id,
          'from_user_id': request.fromUserId,
          'from_public_id': request.fromPublicId,
          'from_user_name': request.fromUserName,
          'to_user_id': request.toUserId,
          'to_public_id': request.toPublicId,
          'status': 'pending',
          'created_at': request.createdAt.toIso8601String(),
        });
      }
    } catch (_) {}

    notifyListeners();
    return true;
  }

  Future<void> acceptFriendRequest(FriendRequest req, {NotificationState? notificationState}) async {
    final newFriendship = Friendship(
      id: 'fr_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
      userId: _currentUser.id,
      friendUserId: req.fromUserId,
      friendPublicId: req.fromPublicId,
      friendName: req.fromUserName,
      createdAt: DateTime.now(),
    );

    _friends.add(newFriendship);
    _incomingRequests.removeWhere((r) => r.id == req.id);
    await _saveToLocal();

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.from('friendships').insert({
          'id': newFriendship.id,
          'user_id': _currentUser.id,
          'friend_user_id': req.fromUserId,
          'friend_public_id': req.fromPublicId,
          'friend_name': req.fromUserName,
          'created_at': newFriendship.createdAt.toIso8601String(),
        });
        await client.from('friend_requests').update({'status': 'accepted'}).eq('id', req.id);
      }
    } catch (_) {}

    notificationState?.notifyFriendRequestAccepted(friendName: req.fromUserName);
    notifyListeners();
  }

  Future<void> rejectFriendRequest(FriendRequest req) async {
    _incomingRequests.removeWhere((r) => r.id == req.id);
    await _saveToLocal();

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.from('friend_requests').update({'status': 'rejected'}).eq('id', req.id);
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> removeFriend(String friendUserId) async {
    _friends.removeWhere((f) => f.friendUserId == friendUserId);
    await _saveToLocal();

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.from('friendships').delete().or('user_id.eq.${_currentUser.id},friend_user_id.eq.${_currentUser.id}');
      }
    } catch (_) {}

    notifyListeners();
  }

  // --- CHALLENGES FLOW ---

  Future<List<Challenge>> sendChallenge({
    required String puzzleHash,
    required List<Friendship> targetFriends,
    required bool won,
    required bool beatMachine,
    required int clues,
    required int rounds,
  }) async {
    final List<Challenge> created = [];

    for (final friend in targetFriends) {
      final challenge = Challenge(
        id: 'chal_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        puzzleHash: puzzleHash.isEmpty ? 'Unknown' : puzzleHash,
        challengerId: _currentUser.id,
        challengerName: _currentUser.displayName,
        challengerWon: won,
        challengerBeatMachine: beatMachine,
        challengerClues: clues,
        challengerRounds: rounds,
        challengeeId: friend.friendUserId,
        challengeeName: friend.friendName,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      _challenges.add(challenge);
      created.add(challenge);

      try {
        final client = Supabase.instance.client;
        if (client.auth.currentUser != null) {
          await client.from('challenges').insert(challenge.toJson());
        }
      } catch (_) {}
    }

    await _saveToLocal();
    notifyListeners();
    return created;
  }

  Future<Challenge> completeChallenge({
    required String challengeId,
    required bool won,
    required bool beatMachine,
    required int clues,
    required int rounds,
    NotificationState? notificationState,
  }) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) {
      throw Exception("Challenge not found.");
    }

    final orig = _challenges[index];
    final winnerId = Challenge.computeWinner(
      challengerId: orig.challengerId,
      challengerWon: orig.challengerWon,
      challengerClues: orig.challengerClues,
      challengerRounds: orig.challengerRounds,
      challengeeId: _currentUser.id,
      challengeeWon: won,
      challengeeClues: clues,
      challengeeRounds: rounds,
    );

    final updated = Challenge(
      id: orig.id,
      puzzleHash: orig.puzzleHash,
      challengerId: orig.challengerId,
      challengerName: orig.challengerName,
      challengerWon: orig.challengerWon,
      challengerBeatMachine: orig.challengerBeatMachine,
      challengerClues: orig.challengerClues,
      challengerRounds: orig.challengerRounds,
      challengeeId: _currentUser.id,
      challengeeName: _currentUser.displayName,
      challengeeWon: won,
      challengeeBeatMachine: beatMachine,
      challengeeClues: clues,
      challengeeRounds: rounds,
      status: 'completed',
      winnerId: winnerId,
      createdAt: orig.createdAt,
      completedAt: DateTime.now(),
    );

    _challenges[index] = updated;
    await _saveToLocal();

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.from('challenges').update(updated.toJson()).eq('id', challengeId);
      }
    } catch (_) {}

    notificationState?.notifyChallengeCompleted(
      challengeeName: _currentUser.displayName,
      puzzleHash: orig.puzzleHash,
      challengeId: challengeId,
    );

    notifyListeners();
    return updated;
  }

  /// Helper to create a sample/mock incoming challenge for testing
  Future<void> addMockIncomingChallenge({NotificationState? notificationState}) async {
    final mockFriend = Friendship(
      id: 'fr_mock',
      userId: _currentUser.id,
      friendUserId: 'usr_turing_master',
      friendPublicId: 'TM-ALPHA1',
      friendName: 'Alan Turing',
      createdAt: DateTime.now(),
    );

    if (!_friends.any((f) => f.friendUserId == mockFriend.friendUserId)) {
      _friends.add(mockFriend);
    }

    final mockChallenge = Challenge(
      id: 'chal_mock_${DateTime.now().millisecondsSinceEpoch}',
      puzzleHash: '#42',
      challengerId: mockFriend.friendUserId,
      challengerName: mockFriend.friendName,
      challengerWon: true,
      challengerBeatMachine: true,
      challengerClues: 3,
      challengerRounds: 2,
      challengeeId: _currentUser.id,
      challengeeName: _currentUser.displayName,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    _challenges.add(mockChallenge);
    await _saveToLocal();

    notificationState?.notifyNewChallengeReceived(
      challengerName: mockFriend.friendName,
      puzzleHash: '#42',
      challengeId: mockChallenge.id,
    );

    notifyListeners();
  }

  /// Helper to create a sample/mock incoming friend request for testing
  Future<void> addMockIncomingFriendRequest({NotificationState? notificationState}) async {
    final mockReq = FriendRequest(
      id: 'req_mock_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: 'usr_ada_lovelace',
      fromPublicId: 'TM-BETA2',
      fromUserName: 'Ada Lovelace',
      toUserId: _currentUser.id,
      toPublicId: _currentUser.publicId,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    if (!_incomingRequests.any((r) => r.id == mockReq.id)) {
      _incomingRequests.add(mockReq);
    }
    await _saveToLocal();

    notificationState?.notifyFriendRequestReceived(
      senderName: 'Ada Lovelace',
      requestId: mockReq.id,
    );

    notifyListeners();
  }

  // --- HEAD TO HEAD STATS ---

  List<HeadToHeadStats> getHeadToHeadStats() {
    final Map<String, HeadToHeadStats> statsMap = {};

    for (final friend in _friends) {
      statsMap[friend.friendUserId] = HeadToHeadStats(
        friendUserId: friend.friendUserId,
        friendName: friend.friendName,
        friendPublicId: friend.friendPublicId,
        userWins: 0,
        friendWins: 0,
        ties: 0,
        totalGames: 0,
      );
    }

    for (final c in pastChallenges) {
      final isChallenger = c.challengerId == _currentUser.id;
      final friendId = isChallenger ? c.challengeeId : c.challengerId;
      final friendName = isChallenger ? c.challengeeName : c.challengerName;

      if (!statsMap.containsKey(friendId)) {
        statsMap[friendId] = HeadToHeadStats(
          friendUserId: friendId,
          friendName: friendName,
          friendPublicId: '',
          userWins: 0,
          friendWins: 0,
          ties: 0,
          totalGames: 0,
        );
      }

      final prev = statsMap[friendId]!;
      int uWins = prev.userWins;
      int fWins = prev.friendWins;
      int ties = prev.ties;

      if (c.winnerId == _currentUser.id) {
        uWins++;
      } else if (c.winnerId == friendId) {
        fWins++;
      } else if (c.winnerId == 'tie') {
        ties++;
      }

      statsMap[friendId] = HeadToHeadStats(
        friendUserId: friendId,
        friendName: friendName,
        friendPublicId: prev.friendPublicId,
        userWins: uWins,
        friendWins: fWins,
        ties: ties,
        totalGames: prev.totalGames + 1,
      );
    }

    return statsMap.values.toList();
  }
}
