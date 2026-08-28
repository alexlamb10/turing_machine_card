import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onContinueAsGuest;
  const LoginScreen({super.key, required this.onContinueAsGuest});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignIn = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isSignIn) {
        await supabase.auth.signInWithPassword(email: email, password: password);
      } else {
        await supabase.auth.signUp(email: email, password: password);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Success!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // TEMPORARY DEBUG HELPER — remove once the auth issue is diagnosed.
  // Makes a raw HTTP request to the same auth endpoint Supabase's SDK
  // hits, and shows the full status code + response body in a dialog,
  // so we can see the raw HTML/error page without needing adb/logcat
  // access on a remote tester's device.
  Future<void> _debugRawRequest() async {
    final client = HttpClient();
    String title;
    String body;
    try {
      final request = await client.postUrl(
        Uri.parse('https://bzkzoezlbiifrubsopzf.supabase.co/auth/v1/signup'),
      );
      request.headers.set(
        'apikey',
        'sb_publishable_1joQL1iUOiS7bfJqxwsTMA_X3_DAOWG',
      );
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode({
        'email': 'debug-check-${DateTime.now().millisecondsSinceEpoch}@example.com',
        'password': 'debugPassword123!',
      })));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      title = 'Status: ${response.statusCode}';
      body = responseBody.length > 4000
          ? '${responseBody.substring(0, 4000)}\n\n...[truncated]'
          : responseBody;
    } catch (e) {
      title = 'Request failed';
      body = e.toString();
    } finally {
      client.close();
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: SelectableText(body),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignIn ? 'Sign In' : 'Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'Turing Machine Companion',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      ),
                      child: Text(_isSignIn ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 18)),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() { _isSignIn = !_isSignIn; });
                },
                child: Text(_isSignIn ? 'Need an account? Sign Up' : 'Already have an account? Sign In'),
              ),
              const Divider(height: 32),
              OutlinedButton.icon(
                onPressed: widget.onContinueAsGuest,
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as Guest'),
              ),
              const SizedBox(height: 24),
              // TEMPORARY — remove after debugging
              TextButton(
                onPressed: _debugRawRequest,
                child: const Text(
                  'Debug: Check Raw Response',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}