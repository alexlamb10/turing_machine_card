import 'package:flutter/foundation.dart';

enum CellState { unknown, crossed, circled }

class GameState extends ChangeNotifier {
  // Grid State: [Column][Number(1-5)] -> State
  // Columns: 0=Blue, 1=Yellow, 2=Purple
  final List<List<CellState>> _grid = List.generate(
    3,
    (_) => List.generate(5, (_) => CellState.unknown),
  );

  List<List<CellState>> get grid => _grid;

  void toggleCell(int col, int number) {
    if (_grid[col][number - 1] == CellState.unknown) {
      _grid[col][number - 1] = CellState.crossed;
    } else if (_grid[col][number - 1] == CellState.crossed) {
      _grid[col][number - 1] = CellState.unknown;
    } else {
      // If it was circled, uncircle it to unknown
      _grid[col][number - 1] = CellState.unknown; 
    }
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
    notifyListeners();
  }

  // Notes per Verifier (A-F)
  final Map<String, String> _verifierNotes = {
    'A': '', 'B': '', 'C': '', 'D': '', 'E': '', 'F': ''
  };
  
  Map<String, String> get verifierNotes => _verifierNotes;

  void updateVerifierNote(String id, String val) {
    _verifierNotes[id] = val;
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
    notifyListeners();
  }
}
