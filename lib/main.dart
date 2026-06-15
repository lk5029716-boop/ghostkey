import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/vault_store.dart';
import 'screens/onboarding_screen.dart';

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
    return ChangeNotifierProvider(
      create: (_) => VaultStore(prefs),
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
          fontFamily: 'Inter',
        ),
        home: SplashScreen(prefs: prefs),
      ),
    );
  }
}
