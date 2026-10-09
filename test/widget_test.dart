import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_machine_card/models/game_state.dart';
import 'package:turing_machine_card/models/stats_state.dart';
import 'package:turing_machine_card/models/challenge_state.dart';
import 'package:turing_machine_card/screens/landing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LandingScreen renders title and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameState()),
          ChangeNotifierProvider(create: (_) => StatsState()),
          ChangeNotifierProvider(create: (_) => ChallengeState()),
        ],
        child: const MaterialApp(
          home: LandingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Turing Machine Companion'), findsWidgets);
    expect(find.text('Start Research'), findsOneWidget);
    expect(find.text('Start Challenge'), findsOneWidget);
  });
}
