import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/grid_cell.dart';
import '../widgets/verifier_input.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turing Machine Note Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Confirm reset
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Game?'),
                  content: const Text('This will clear all marks and notes.'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    TextButton(
                      child: const Text('Reset', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        context.read<GameState>().reset();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Section: Inputs (Left) vs Verifiers+Grid (Right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Guess Inputs
                Expanded(
                  flex: 2,
                  child: _buildGuessInputs(context),
                ),
                const SizedBox(width: 16),
                // Right: Verifiers & Grid
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildVerifiers(context),
                      const SizedBox(height: 16),
                      _buildGrid(context),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Bottom: Notes
            _buildNotes(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGuessInputs(BuildContext context) {
    final state = context.watch<GameState>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Shapes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.change_history, color: Colors.blue)), // Triangle
            const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.crop_square, color: Colors.orange)), // Square (Yellow)
            const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.circle, color: Colors.purple)), // Circle
          ],
        ),
        const SizedBox(height: 8),
        // 9 Rows of Inputs
        ...List.generate(9, (row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Expanded(child: _buildCompactSelector(context, state.guesses[row][0], (v) => state.setGuess(row, 0, v), Colors.blue[50]!)),
                const SizedBox(width: 4),
                Expanded(child: _buildCompactSelector(context, state.guesses[row][1], (v) => state.setGuess(row, 1, v), Colors.amber[50]!)),
                const SizedBox(width: 4),
                Expanded(child: _buildCompactSelector(context, state.guesses[row][2], (v) => state.setGuess(row, 2, v), Colors.purple[50]!)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCompactSelector(BuildContext context, int? value, Function(int?) onChanged, Color color) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          iconSize: 16,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(
            value: e,
            child: Center(child: Text(e.toString())),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildVerifiers(BuildContext context) {
    final state = context.watch<GameState>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ['A', 'B', 'C', 'D', 'E', 'F'].map((id) {
        return VerifierInput(
          id: id,
          state: state.verifierStates[id] ?? 0,
          onTap: () => state.cycleVerifier(id),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final state = context.watch<GameState>();
    // 3 Columns x 5 Rows
    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      children: List.generate(5, (row) { // Rows 1-5
        int number = row + 1;
        return TableRow(
          children: [
            // Blue Column (0)
            GridCell(
              number: number, 
              column: 0, 
              state: state.grid[0][row],
              onTap: () => state.toggleCell(0, number),
              onLongPress: () => state.circleCell(0, number),
            ),
            // Yellow Column (1)
            GridCell(
              number: number, 
              column: 1, 
              state: state.grid[1][row],
              onTap: () => state.toggleCell(1, number),
              onLongPress: () => state.circleCell(1, number),
            ),
            // Purple Column (2)
            GridCell(
              number: number, 
              column: 2, 
              state: state.grid[2][row],
              onTap: () => state.toggleCell(2, number),
              onLongPress: () => state.circleCell(2, number),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNotes(BuildContext context) {
    final state = context.watch<GameState>();
    // We use a TextEditingController in a StatefulWidget usually, 
    // but for simple state syncing in this stateless widget we rely on onChanged.
    // However, recreating the controller every build is bad.
    // Let's just use the state value.
    // Ideally this widget should be its own stateful widget to handle focus/controller properly.
    // For MVP, we'll just display it.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            initialValue: state.notes,
            maxLines: null,
            decoration: const InputDecoration.collapsed(hintText: 'Enter your deductions here...'),
            onChanged: (val) => state.updateNotes(val),
          ),
        ),
      ],
    );
  }
}
