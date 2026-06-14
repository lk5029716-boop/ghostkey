import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const GhostKeyApp());

class GhostKeyApp extends StatelessWidget {
  const GhostKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GhostKey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1226),
        primaryColor: const Color(0xFFF0D25A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF0D25A),
          secondary: Color(0xFF1C2040),
          surface: Color(0xFF151833),
          onSurface: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF0D25A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key, size: 64, color: Color(0xFF0F1226)),
            ),
            const SizedBox(height: 24),
            const Text('GhostKey', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFF0D25A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, size: 80, color: Color(0xFF0F1226)),
            ),
            const SizedBox(height: 32),
            const Text('Your digital life. Passed on automatically.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('GhostKey stores your secrets encrypted, then releases them when you cannot.',
                style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const VaultDashboard()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF0D25A),
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Get started'),
            ),
          ],
        ),
      ),
    );
  }
}

class VaultDashboard extends StatelessWidget {
  const VaultDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2040),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0D25A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer, color: Color(0xFF0F1226)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Timer active\n45 days remaining', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Secrets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const _SecretTile(title: 'Gmail recovery', description: 'user@email.com'),
          const _SecretTile(title: 'Bitcoin seed', description: '12 words'),
          const _SecretTile(title: 'AWS root', description: 'admin@company'),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFF0D25A),
        child: const Icon(Icons.add, color: Color(0xFF0F1226)),
      ),
    );
  }
}

class _SecretTile extends StatelessWidget {
  final String title;
  final String description;
  const _SecretTile({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151833),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C2040)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1C2040),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.key, color: Color(0xFFF0D25A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.lock, size: 16, color: Colors.white38),
        ],
      ),
    );
  }
}
