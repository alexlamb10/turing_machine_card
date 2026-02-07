import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const TuringMachineApp(),
    ),
  );
}

class TuringMachineApp extends StatelessWidget {
  const TuringMachineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turing Machine Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
