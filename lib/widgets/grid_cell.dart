import 'package:flutter/material.dart';
import '../models/game_state.dart';

class GridCell extends StatelessWidget {
  final int number;
  final int column; // 0=Blue, 1=Yellow, 2=Purple
  final CellState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const GridCell({
    super.key,
    required this.number,
    required this.column,
    required this.state,
    required this.onTap,
    required this.onLongPress,
  });

  Color get _color {
    switch (column) {
      case 0: return Colors.blue[100]!;
      case 1: return Colors.amber[100]!; // Yellow
      case 2: return Colors.purple[100]!;
      default: return Colors.grey[200]!;
    }
  }

  Color get _borderColor {
    switch (column) {
      case 0: return Colors.blue;
      case 1: return Colors.orange; // Yellow acts weird on white
      case 2: return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: _color,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$number',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: state == CellState.crossed ? Colors.grey[400] : Colors.black,
              ),
            ),
            if (state == CellState.crossed)
              const Icon(Icons.close, color: Colors.red, size: 28),
            if (state == CellState.circled)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
