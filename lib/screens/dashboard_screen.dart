import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const DashboardScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1226),
      body: const Center(
        child: Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 24)),
      ),
    );
  }
}
