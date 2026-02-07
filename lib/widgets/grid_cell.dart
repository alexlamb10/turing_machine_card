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

  Color get _baseColor {
    switch (column) {
      case 0: return const Color(0xFF00AACC); // Blue
      case 1: return const Color(0xFFE8C502); // Yellow
      case 2: return const Color(0xFF6E50AA); // Purple
      default: return Colors.grey;
    }
  }

  Color get _color => _baseColor.withOpacity(0.3);
  Color get _borderColor => _baseColor;

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
              const Positioned.fill(
                child: Center(child: Icon(Icons.close, color: Colors.red, size: 28)),
              ),
            if (state == CellState.circled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
