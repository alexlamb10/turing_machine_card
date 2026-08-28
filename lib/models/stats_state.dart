import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameRecord {
  final String id;
  final String puzzleHash;
  final String outcome; // 'win', 'loss', 'beat_machine'
  final DateTime playedAt;

  GameRecord({
    required this.id,
    required this.puzzleHash,
    required this.outcome,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'puzzleHash': puzzleHash,
        'outcome': outcome,
        'playedAt': playedAt.toIso8601String(),
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        id: json['id'] ?? '',
        puzzleHash: json['puzzleHash'] ?? 'Unknown',
        outcome: json['outcome'] ?? 'loss',
        playedAt: DateTime.parse(json['playedAt'] ?? DateTime.now().toIso8601String()),
      );
}

class StatsState extends ChangeNotifier {
  int _wins = 0;
  int _losses = 0;
  int _machineBeats = 0;
  bool _isLoading = true;
  List<GameRecord> _history = [];

  int get wins => _wins;
  int get losses => _losses;
  int get machineBeats => _machineBeats;
  bool get isLoading => _isLoading;
  List<GameRecord> get history => _history;

  StatsState() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    _wins = prefs.getInt('wins') ?? 0;
    _losses = prefs.getInt('losses') ?? 0;
    _machineBeats = prefs.getInt('machineBeats') ?? 0;

    // Load local history as fallback
    final historyRaw = prefs.getStringList('history') ?? [];
    _history = historyRaw
        .map((e) => GameRecord.fromJson(jsonDecode(e)))
        .toList();

    // Fetch remote history from Supabase if logged in
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final response = await client
            .from('games')
            .select()
            .order('played_at', ascending: false);

        _history = (response as List).map((row) {
          return GameRecord(
            id: row['id'] ?? '',
            puzzleHash: row['puzzle_hash'] ?? 'Unknown',
            outcome: row['outcome'] ?? 'loss',
            playedAt: DateTime.parse(row['played_at']),
          );
        }).toList();

        // Calculate totals dynamically from database records
        _wins = _history.where((r) => r.outcome == 'win' || r.outcome == 'beat_machine').length;
        _losses = _history.where((r) => r.outcome == 'loss').length;
        _machineBeats = _history.where((r) => r.outcome == 'beat_machine').length;
      }
    } catch (_) {
      // Fallback to local storage if offline or request fails
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _addRecord(String puzzleHash, String outcome) async {
    final record = GameRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      puzzleHash: puzzleHash,
      outcome: outcome,
      playedAt: DateTime.now(),
    );

    _history.insert(0, record);

    final prefs = await SharedPreferences.getInstance();
    final rawList = _history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('history', rawList);

    // Try optional sync with Supabase
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('games').insert({
          'id': record.id,
          'user_id': user.id,
          'puzzle_hash': record.puzzleHash,
          'outcome': record.outcome,
          'played_at': record.playedAt.toIso8601String(),
        });
      }
    } catch (_) {
      // Ignored if offline or placeholder keys are used
    }
  }

  Future<void> addWin({String puzzleHash = 'Unknown'}) async {
    _wins++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wins', _wins);
    await _addRecord(puzzleHash, 'win');
    notifyListeners();
  }

  Future<void> addLoss({String puzzleHash = 'Unknown'}) async {
    _losses++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('losses', _losses);
    await _addRecord(puzzleHash, 'loss');
    notifyListeners();
  }

  Future<void> addMachineBeat({String puzzleHash = 'Unknown'}) async {
    _wins++;
    _machineBeats++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wins', _wins);
    await prefs.setInt('machineBeats', _machineBeats);
    await _addRecord(puzzleHash, 'beat_machine');
    notifyListeners();
  }

  Future<void> deleteRecord(String recordId) async {
    _history.removeWhere((r) => r.id == recordId);

    final prefs = await SharedPreferences.getInstance();
    final rawList = _history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('history', rawList);

    // Recalculate totals dynamically
    _wins = _history.where((r) => r.outcome == 'win' || r.outcome == 'beat_machine').length;
    _losses = _history.where((r) => r.outcome == 'loss').length;
    _machineBeats = _history.where((r) => r.outcome == 'beat_machine').length;

    await prefs.setInt('wins', _wins);
    await prefs.setInt('losses', _losses);
    await prefs.setInt('machineBeats', _machineBeats);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('games').delete().eq('id', recordId);
      }
    } catch (_) {
      // Ignored if offline
    }

    notifyListeners();
  }
}
