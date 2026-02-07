import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CellState { unknown, crossed, circled }

class GameState extends ChangeNotifier {
  // Grid State: [Column][Number(1-5)] -> State
  // Columns: 0=Blue, 1=Yellow, 2=Purple
  final List<List<CellState>> _grid = List.generate(
    3,
    (_) => List.generate(5, (_) => CellState.unknown),
  );

  List<List<CellState>> get grid => _grid;

  GameState() {
    _loadState();
  }

  void toggleCell(int col, int number) {
    if (_grid[col][number - 1] == CellState.unknown) {
      _grid[col][number - 1] = CellState.crossed;
    } else if (_grid[col][number - 1] == CellState.crossed) {
      _grid[col][number - 1] = CellState.unknown;
    } else {
      // If it was circled, uncircle it to unknown
      _grid[col][number - 1] = CellState.unknown; 
    }
    _saveState();
    notifyListeners();
  }

  void circleCell(int col, int number) {
     if (_grid[col][number - 1] == CellState.circled) {
      _grid[col][number - 1] = CellState.unknown;
    } else {
      _grid[col][number - 1] = CellState.circled;
      // Optionally cross out others in same column? 
      // For now let's keep it manual as users might want full control.
    }
    _saveState();
    notifyListeners();
  }
  
  // Verifier States: 9 Rows, 6 Verifiers (A-F)
  // [Row 0-8][VerifierID] -> State (0=Empty, 1=Fail, 2=Pass)
  final List<Map<String, int>> _roundVerifiers = List.generate(
    9,
    (_) => {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0},
  );
  
  List<Map<String, int>> get roundVerifiers => _roundVerifiers;

  void cycleRoundVerifier(int row, String id) {
    int current = _roundVerifiers[row][id] ?? 0;
    _roundVerifiers[row][id] = (current + 1) % 3;
    _saveState();
    notifyListeners();
  }

  // Guesses: 9 Rows, 3 Columns (Blue, Yellow, Purple)
  // [Row 0-8][Col 0-2]
  final List<List<int?>> _guesses = List.generate(
    9,
    (_) => [null, null, null],
  );

  List<List<int?>> get guesses => _guesses;

  void setGuess(int row, int col, int? val) {
    _guesses[row][col] = val;
    _saveState();
    notifyListeners();
  }

  // Notes per Verifier (A-F)
  final Map<String, String> _verifierNotes = {
    'A': '', 'B': '', 'C': '', 'D': '', 'E': '', 'F': ''
  };
  
  Map<String, String> get verifierNotes => _verifierNotes;

  void updateVerifierNote(String id, String val) {
    _verifierNotes[id] = val;
    _saveState();
    notifyListeners();
  }
  
  // Disabled Verifiers (e.g. E/F not in use)
  final Set<String> _disabledVerifiers = {};

  bool isVerifierDisabled(String id) => _disabledVerifiers.contains(id);

  void toggleVerifierDisabled(String id) {
    if (_disabledVerifiers.contains(id)) {
      _disabledVerifiers.remove(id);
    } else {
      _disabledVerifiers.add(id);
    }
    _saveState();
    notifyListeners();
  }

  void reset() {
    for (var col in _grid) {
      for (var i = 0; i < 5; i++) {
        col[i] = CellState.unknown;
      }
    }
    // Reset verifiers for all rounds
    for (var row in _roundVerifiers) {
      row.updateAll((key, value) => 0);
    }
    // Reset guesses
    for (var row in _guesses) {
      row[0] = null;
      row[1] = null;
      row[2] = null;
    }
    _verifierNotes.updateAll((key, value) => '');
    _disabledVerifiers.clear();
    _saveState();
    notifyListeners();
  }

  // Persistence Logic
  static const _storageKey = 'turing_machine_game_state';

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'grid': _grid.map((col) => col.map((cell) => cell.index).toList()).toList(),
      'roundVerifiers': _roundVerifiers,
      'guesses': _guesses,
      'verifierNotes': _verifierNotes,
      'disabledVerifiers': _disabledVerifiers.toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Load Grid
      if (data.containsKey('grid')) {
        final gridData = (data['grid'] as List).map((col) => (col as List).cast<int>()).toList();
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 5; j++) {
            if (i < gridData.length && j < gridData[i].length) {
              _grid[i][j] = CellState.values[gridData[i][j]];
            }
          }
        }
      }

      // Load Round Verifiers
      if (data.containsKey('roundVerifiers')) {
        final rvData = (data['roundVerifiers'] as List).cast<Map<String, dynamic>>();
        for (int i = 0; i < 9; i++) {
          if (i < rvData.length) {
             _roundVerifiers[i] = rvData[i].map((key, value) => MapEntry(key, value as int));
          }
        }
      }

      // Load Guesses
      if (data.containsKey('guesses')) {
        final guessesData = (data['guesses'] as List).map((row) => (row as List).cast<int?>()).toList();
        for (int i = 0; i < 9; i++) {
          if (i < guessesData.length) {
            _guesses[i] = guessesData[i];
          }
        }
      }

      // Load Notes
      if (data.containsKey('verifierNotes')) {
        final notesData = Map<String, String>.from(data['verifierNotes']);
        _verifierNotes.addAll(notesData);
      }

      // Load Disabled Verifiers
      if (data.containsKey('disabledVerifiers')) {
        final disabledData = (data['disabledVerifiers'] as List).cast<String>();
        _disabledVerifiers.clear();
        _disabledVerifiers.addAll(disabledData);
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading game state: $e');
      }
    }
  }
}
