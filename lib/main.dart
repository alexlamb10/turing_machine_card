import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/game_state.dart';
import 'models/stats_state.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';

/// Forces all dart:io-based HTTP clients (including the one Supabase's
/// auth client uses under the hood) to resolve and connect using IPv4
/// only, working around a known Dart SDK bug with IPv4/IPv6 connection
/// handling. Since overriding `connectionFactory` bypasses HttpClient's
/// automatic TLS handling, we perform the TLS handshake explicitly for
/// https:// requests via SecureSocket.secure, using the original
/// hostname for proper SNI/certificate validation.
class IPv4OnlyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory =
        (Uri uri, String? proxyHost, int? proxyPort) async {
      final addresses = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.IPv4,
      );
      if (addresses.isEmpty) {
        throw SocketException('No IPv4 address found for ${uri.host}');
      }

      final rawSocket = await Socket.connect(addresses.first, uri.port);

      if (uri.scheme == 'https') {
        final secureSocket = await SecureSocket.secure(
          rawSocket,
          host: uri.host, // preserves correct hostname for SNI/cert checks
          context: context,
        );
        return ConnectionTask.fromSocket(
          Future.value(secureSocket),
          () => secureSocket.destroy(),
        );
      }

      return ConnectionTask.fromSocket(
        Future.value(rawSocket),
        () => rawSocket.destroy(),
      );
    };
    return client;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be set before any HTTP clients (including Supabase's) are created.
  HttpOverrides.global = IPv4OnlyHttpOverrides();

  await Supabase.initialize(
    url: 'https://bzkzoezlbiifrubsopzf.supabase.co',
    anonKey: 'sb_publishable_1joQL1iUOiS7bfJqxwsTMA_X3_DAOWG',
  );

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
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isGuest = false;

  @override
  Widget build(BuildContext context) {
    if (_isGuest) {
      return const LandingScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return const LandingScreen();
        }
        return LoginScreen(
          onContinueAsGuest: () {
            setState(() {
              _isGuest = true;
            });
          },
        );
      },
    );
  }
}