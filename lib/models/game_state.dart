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
  
  // Verifier States
  // A-F. 0=Empty, 1=Cross(Fail), 2=Check(Pass)
  final Map<String, int> _verifierStates = {
    'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0
  };
  
  Map<String, int> get verifierStates => _verifierStates;

  void cycleVerifier(String id) {
    _verifierStates[id] = (_verifierStates[id]! + 1) % 3;
    notifyListeners();
  }

  // Guesses
  int? blueGuess;
  int? yellowGuess;
  int? purpleGuess;

  void setGuess(int col, int? val) {
    if (col == 0) blueGuess = val;
    if (col == 1) yellowGuess = val;
    if (col == 2) purpleGuess = val;
    notifyListeners();
  }

  // Notes
  String notes = "";
  void updateNotes(String val) {
    notes = val;
    notifyListeners();
  }
  
  void reset() {
    for (var col in _grid) {
      for (var i = 0; i < 5; i++) {
        col[i] = CellState.unknown;
      }
    }
    _verifierStates.updateAll((key, value) => 0);
    blueGuess = null;
    yellowGuess = null;
    purpleGuess = null;
    notes = "";
    notifyListeners();
  }
}
