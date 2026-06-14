import 'package:flutter/material.dart';

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
