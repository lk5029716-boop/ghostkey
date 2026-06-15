import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(GhostKeyApp(prefs: prefs));
}

class GhostKeyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const GhostKeyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Provider<SharedPreferences>.value(
      value: prefs,
      child: MaterialApp(
        title: 'GhostKey',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F1226),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF0D25A),
            secondary: Color(0xFF1C2040),
            surface: Color(0xFF151833),
            onSurface: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1226),
      body: SafeArea(
        child: Column(children: [
          // Status bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('9:30', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8))),
              Row(children: [
                Icon(Icons.signal_cellular_4_bar, size: 16, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Icon(Icons.wifi, size: 16, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Icon(Icons.battery_full, size: 16, color: Colors.white.withOpacity(0.8)),
              ]),
            ]),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Logo with glow
                SizedBox(width: 128, height: 128,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0D25A).withOpacity(0.2),
                        boxShadow: [BoxShadow(color: Color(0xFFF0D25A).withOpacity(0.15), blurRadius: 40, spreadRadius: 20)])),
                    const Icon(Icons.shield, size: 72, color: Color(0xFFF0D25A)),
                  ]),
                ),
                const SizedBox(height: 32),
                const Text('GhostKey', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.25)),
                const SizedBox(height: 8),
                const Text('Your digital legacy secured.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white54, letterSpacing: 0.5)),
                const SizedBox(height: 48),
                // Features
                SizedBox(width: 320, child: Column(children: [
                  _feat(Icons.vpn_key, 'Bank-grade encryption'),
                  const SizedBox(height: 24),
                  _feat(Icons.alarm_on, 'Dead man switch'),
                  const SizedBox(height: 24),
                  _feat(Icons.shield_person, 'Secure inheritance'),
                ])),
              ]),
            ),
          ),
          // Bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              SizedBox(width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B6D24), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 4),
                  child: const Text('Get started', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(fontSize: 14, color: Colors.white54)),
                GestureDetector(onTap: () {}, child: const Text('Sign in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF88D982)))),
              ]),
              const SizedBox(height: 32),
              FractionallySizedBox(widthFactor: 1 / 3, child: Container(height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 8),
            ]),
          ),
        ]),
      ),
    );
  }

  static Widget _feat(IconData icon, String label) {
    return Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(0xFF88D982).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 18, color: Color(0xFF88D982))),
      const SizedBox(width: 16),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white54)),
    ]);
  }
}
