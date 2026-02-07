import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'models/stats_state.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider(create: (_) => StatsState()),
      ],
      child: MaterialApp(
        title: 'Turing Machine Card',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          useMaterial3: true,
        ),
        home: const LandingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
