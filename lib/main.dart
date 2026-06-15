import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─── Colors ───
class C {
  static const bg = Color(0xFF0F1226);
  static const card = Color(0xFF1C2040);
  static const surface = Color(0xFF151833);
  static const primary = Color(0xFFF0D25A);
  static const green = Color(0xFF1B6D24);
  static const greenLight = Color(0xFF88D982);
  static const text = Colors.white;
  static const textMid = Colors.white54;
  static const textDim = Colors.white24;
  static const err = Color(0xFFBA1A1A);
}

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
          scaffoldBackgroundColor: C.bg,
          colorScheme: const ColorScheme.dark(
            primary: C.primary,
            secondary: C.card,
            surface: C.surface,
            onSurface: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: SplashScreen(prefs: prefs),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SPLASH SCREEN
// ═══════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const SplashScreen({super.key, required this.prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final hasPin = widget.prefs.getString('pin') != null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasPin
            ? PinLoginScreen(prefs: widget.prefs)
            : OnboardingScreen(prefs: widget.prefs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: const BoxDecoration(color: C.primary, shape: BoxShape.circle),
              child: const Icon(Icons.vpn_key, size: 64, color: C.bg),
            ),
            const SizedBox(height: 24),
            const Text('GhostKey', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: C.text)),
            const SizedBox(height: 8),
            const Text('Your digital executor', style: TextStyle(color: C.textMid, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// ONBOARDING SCREEN (matches your HTML)
// ═══════════════════════════════════════════
class OnboardingScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const OnboardingScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('9:30', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8))),
                  Row(children: [
                    Icon(Icons.signal_cellular_4_bar, size: 16, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Icon(Icons.wifi, size: 16, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Icon(Icons.battery_full, size: 16, color: Colors.white.withOpacity(0.8)),
                  ]),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with glow
                    SizedBox(
                      width: 128, height: 128,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: C.primary.withOpacity(0.2),
                              boxShadow: [BoxShadow(color: C.primary.withOpacity(0.15), blurRadius: 40, spreadRadius: 20)],
                            ),
                          ),
                          const Icon(Icons.shield, size: 72, color: C.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('GhostKey', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: C.text, letterSpacing: -0.25)),
                    const SizedBox(height: 8),
                    const Text('Your digital legacy secured.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: C.textMid, letterSpacing: 0.5)),
                    const SizedBox(height: 48),
                    // Features
                    SizedBox(
                      width: 320,
                      child: Column(children: [
                        _feat(Icons.vpn_key, 'Bank-grade encryption'),
                        const SizedBox(height: 24),
                        _feat(Icons.alarm_on, "Dead man's switch"),
                        const SizedBox(height: 24),
                        _feat(Icons.shield_person, 'Secure inheritance'),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => PinSetupScreen(prefs: prefs)),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: C.green, foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 4,
                    ),
                    child: const Text('Get started', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: C.textMid, letterSpacing: 0.25)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => PinLoginScreen(prefs: prefs)),
                    ),
                    child: const Text('Sign in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.greenLight, letterSpacing: 0.5)),
                  ),
                ]),
                const SizedBox(height: 32),
                FractionallySizedBox(
                  widthFactor: 1 / 3,
                  child: Container(height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _feat(IconData icon, String label) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: C.greenLight.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: C.greenLight),
      ),
      const SizedBox(width: 16),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: C.textMid, letterSpacing: 0.1)),
    ]);
  }
}

// ═══════════════════════════════════════════
// PIN SETUP SCREEN
// ═══════════════════════════════════════════
class PinSetupScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const PinSetupScreen({super.key, required this.prefs});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  bool _confirming = false;
  String _firstPin = '';

  void _onComplete() {
    if (_pin.length < 6) return;
    if (!_confirming) {
      setState(() { _firstPin = _pin; _pin = ''; _confirming = true; });
    } else if (_pin == _firstPin) {
      widget.prefs.setString('pin', _pin);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(prefs: widget.prefs)),
      );
    } else {
      setState(() { _pin = ''; _confirming = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match. Try again.'), backgroundColor: C.card),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: _confirming ? IconButton(icon: const Icon(Icons.arrow_back, color: C.text), onPressed: () => setState(() { _confirming = false; _pin = ''; })) : null,
        title: Text(_confirming ? 'Confirm PIN' : 'Create PIN', style: const TextStyle(color: C.text)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_confirming ? 'Re-enter your 6-digit PIN' : 'Create a 6-digit PIN to secure your vault',
                style: const TextStyle(fontSize: 14, color: C.textMid), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            PinPad(onChanged: (p) => setState(() => _pin = p), onComplete: _onComplete),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// PIN LOGIN SCREEN
// ═══════════════════════════════════════════
class PinLoginScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const PinLoginScreen({super.key, required this.prefs});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';

  void _onComplete() {
    if (_pin.length < 6) return;
    if (_pin == widget.prefs.getString('pin')) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardScreen(prefs: widget.prefs)), (r) => false,
      );
    } else {
      setState(() => _pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN'), backgroundColor: C.card),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: C.text), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline, size: 56, color: C.primary),
            const SizedBox(height: 24),
            const Text('Enter your PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.text)),
            const SizedBox(height: 32),
            PinPad(onChanged: (p) => setState(() => _pin = p), onComplete: _onComplete),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// PIN PAD WIDGET
// ═══════════════════════════════════════════
class PinPad extends StatefulWidget {
  final void Function(String) onChanged;
  final VoidCallback onComplete;
  const PinPad({super.key, required this.onChanged, required this.onComplete});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _onKey(String key) {
    setState(() {
      if (key == 'del') { if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1); }
      else if (_pin.length < 6) _pin += key;
    });
    widget.onChanged(_pin);
    if (_pin.length == 6) Future.delayed(const Duration(milliseconds: 200), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 18, height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? C.primary : C.textDim),
        );
      })),
      const SizedBox(height: 48),
      SizedBox(
        width: 270,
        child: GridView.count(
          shrinkWrap: true, crossAxisCount: 3, childAspectRatio: 1.6,
          mainAxisSpacing: 8, crossAxisSpacing: 8,
          children: [
            ...['1','2','3','4','5','6','7','8','9'].map((k) => _kb(k, () => _onKey(k))),
            _kb('', () => _onKey('del'), icon: Icons.backspace_outlined),
            _kb('0', () => _onKey('0')),
            const SizedBox.shrink(),
          ],
        ),
      ),
    ]);
  }

  Widget _kb(String label, VoidCallback onTap, {IconData? icon}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: C.card.withOpacity(0.5),
      ),
      child: icon != null
          ? Icon(icon, color: C.text, size: 22)
          : Text(label, style: const TextStyle(fontSize: 26, color: C.text)),
    );
  }
}

// ═══════════════════════════════════════════
// DASHBOARD SCREEN
// ═══════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const DashboardScreen({super.key, required this.prefs});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _daysRemaining = 45;
  final List<Map<String, String>> _secrets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('My Vault', style: TextStyle(color: C.text)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(prefs: widget.prefs))),
            icon: const Icon(Icons.settings, color: C.text),
          ),
        ],
      ),
      body: _secrets.isEmpty ? _empty() : _list(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add secret — coming soon')));
        },
        backgroundColor: C.primary,
        child: const Icon(Icons.add, color: C.bg),
      ),
    );
  }

  Widget _empty() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Timer card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: const BoxDecoration(color: C.primary, shape: BoxShape.circle), child: const Icon(Icons.timer, color: C.bg)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Inactivity Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$_daysRemaining days remaining', style: const TextStyle(color: C.textMid)),
          ])),
          TextButton(onPressed: () => setState(() => _daysRemaining = 45), child: const Text('Check-in', style: TextStyle(color: C.primary))),
        ]),
      ),
      const SizedBox(height: 24),
      // Heirs card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: const BoxDecoration(color: C.card, shape: BoxShape.circle), child: const Icon(Icons.people, color: C.primary)),
          const SizedBox(width: 16),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Heirs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('No heirs added', style: TextStyle(color: C.textMid)),
          ])),
          TextButton(onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Heir management — coming soon')));
          }, child: const Text('Add', style: TextStyle(color: C.primary))),
        ]),
      ),
      const SizedBox(height: 32),
      const Center(child: Column(children: [
        Icon(Icons.lock_open, size: 56, color: C.textDim),
        SizedBox(height: 12),
        Text('No secrets yet', style: TextStyle(color: C.textMid, fontSize: 16)),
        SizedBox(height: 4),
        Text('Tap + to add your first secret', style: TextStyle(color: C.textDim, fontSize: 13)),
      ])),
    ]);
  }

  Widget _list() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.timer, color: C.primary),
          const SizedBox(width: 12),
          Expanded(child: Text('$_daysRemaining days remaining')),
          TextButton(onPressed: () => setState(() => _daysRemaining = 45), child: const Text('Check-in', style: TextStyle(color: C.primary))),
        ]),
      ),
      const SizedBox(height: 16),
      const Text('Secrets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ..._secrets.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.card)),
        child: Row(children: [
          const Icon(Icons.key, color: C.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(s['description'] ?? '', style: const TextStyle(color: C.textMid, fontSize: 12)),
          ])),
          const Icon(Icons.lock, size: 14, color: C.textDim),
        ]),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════
// SETTINGS SCREEN
// ═══════════════════════════════════════════
class SettingsScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const SettingsScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: C.text)),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
          leading: const Icon(Icons.timer, color: C.text),
          title: const Text('Inactivity Timer', style: TextStyle(color: C.text)),
          subtitle: const Text('Configure timer duration', style: TextStyle(color: C.textMid)),
          trailing: const Icon(Icons.chevron_right, color: C.textMid),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.people, color: C.text),
          title: const Text('Manage Heirs', style: TextStyle(color: C.text)),
          subtitle: const Text('Add or remove heirs', style: TextStyle(color: C.textMid)),
          trailing: const Icon(Icons.chevron_right, color: C.textMid),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.security, color: C.text),
          title: const Text('Change PIN', style: TextStyle(color: C.text)),
          subtitle: const Text('Update your security PIN', style: TextStyle(color: C.textMid)),
          trailing: const Icon(Icons.chevron_right, color: C.textMid),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.vpn_key, color: C.text),
          title: const Text('2FA', style: TextStyle(color: C.text)),
          subtitle: const Text('Two-factor authentication', style: TextStyle(color: C.textMid)),
          trailing: const Icon(Icons.chevron_right, color: C.textMid),
          onTap: () {},
        ),
        const Divider(color: C.textDim),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Lock Vault', style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => SplashScreen(prefs: prefs)), (r) => false,
            );
          },
        ),
      ]),
    );
  }
}
