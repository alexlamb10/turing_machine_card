import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsState extends ChangeNotifier {
  int _wins = 0;
  int _losses = 0;
  int _machineBeats = 0;
  bool _isLoading = true;

  int get wins => _wins;
  int get losses => _losses;
  int get machineBeats => _machineBeats;
  bool get isLoading => _isLoading;

  StatsState() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    _wins = prefs.getInt('wins') ?? 0;
    _losses = prefs.getInt('losses') ?? 0;
    _machineBeats = prefs.getInt('machineBeats') ?? 0;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWin() async {
    _wins++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wins', _wins);
    notifyListeners();
  }

  Future<void> addLoss() async {
    _losses++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('losses', _losses);
    notifyListeners();
  }

  Future<void> addMachineBeat() async {
    _machineBeats++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('machineBeats', _machineBeats);
    notifyListeners();
  }
}
