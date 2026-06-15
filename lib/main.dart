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
        home: OnboardingScreen(prefs: prefs),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const OnboardingScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1226),
      body: SafeArea(
        child: Column(children: [
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              SizedBox(width: double.infinity,
                child: FilledButton(
                  onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PinSetupScreen(prefs: prefs))); },
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
    if (!_confirming) { setState(() { _firstPin = _pin; _pin = ''; _confirming = true; }); }
    else if (_pin == _firstPin) { widget.prefs.setString('pin', _pin); Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DashboardScreen(prefs: widget.prefs))); }
    else { setState(() { _pin = ''; _confirming = false; }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match'), backgroundColor: Color(0xFF1C2040))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1226),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: _confirming ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() { _confirming = false; _pin = ''; })) : null, title: Text(_confirming ? 'Confirm PIN' : 'Create PIN', style: const TextStyle(color: Colors.white))),
      body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_confirming ? 'Re-enter your 6-digit PIN' : 'Create a 6-digit PIN', style: const TextStyle(fontSize: 14, color: Colors.white54), textAlign: TextAlign.center), const SizedBox(height: 32), PinPad(onChanged: (p) => setState(() => _pin = p), onComplete: _onComplete)]))),
    );
  }
}

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
    setState(() { if (key == 'del') { if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1); } else if (_pin.length < 6) _pin += key; });
    widget.onChanged(_pin);
    if (_pin.length == 6) Future.delayed(const Duration(milliseconds: 200), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) {
        return AnimatedContainer(duration: const Duration(milliseconds: 150), width: 18, height: 18, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? const Color(0xFFF0D25A) : Colors.white24));
      })),
      const SizedBox(height: 48),
      SizedBox(width: 270, child: GridView.count(shrinkWrap: true, crossAxisCount: 3, childAspectRatio: 1.6, mainAxisSpacing: 8, crossAxisSpacing: 8, children: [
        ...['1','2','3','4','5','6','7','8','9'].map((k) => _kb(k, () => _onKey(k))),
        _kb('', () => _onKey('del'), icon: Icons.backspace_outlined),
        _kb('0', () => _onKey('0')),
        const SizedBox.shrink(),
      ])),
    ]);
  }

  Widget _kb(String label, VoidCallback onTap, {IconData? icon}) {
    return TextButton(onPressed: onTap, style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: const Color(0xFF1C2040).withOpacity(0.5)), child: icon != null ? Icon(icon, color: Colors.white, size: 22) : Text(label, style: const TextStyle(fontSize: 26, color: Colors.white)));
  }
}

class DashboardScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const DashboardScreen({super.key, required this.prefs});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _daysRemaining = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1226),
      appBar: AppBar(title: const Text('My Vault', style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, actions: [IconButton(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(prefs: widget.prefs))); }, icon: const Icon(Icons.settings, color: Colors.white))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1C2040), borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(width: 52, height: 52, decoration: const BoxDecoration(color: Color(0xFFF0D25A), shape: BoxShape.circle), child: const Icon(Icons.timer, color: Color(0xFF0F1226))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Inactivity Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('$_daysRemaining days remaining', style: const TextStyle(color: Colors.white54))])), TextButton(onPressed: () => setState(() => _daysRemaining = 45), child: const Text('Check-in', style: TextStyle(color: Color(0xFFF0D25A))))])),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1C2040), borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(width: 52, height: 52, decoration: const BoxDecoration(color: Color(0xFF1C2040), shape: BoxShape.circle), child: const Icon(Icons.people, color: Color(0xFFF0D25A))), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Heirs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), SizedBox(height: 4), Text('No heirs added', style: TextStyle(color: Colors.white54))])), TextButton(onPressed: () {}, child: const Text('Add', style: TextStyle(color: Color(0xFFF0D25A))))])),
        const SizedBox(height: 32),
        const Center(child: Column(children: [Icon(Icons.lock_open, size: 56, color: Colors.white24), SizedBox(height: 12), Text('No secrets yet', style: TextStyle(color: Colors.white54, fontSize: 16)), SizedBox(height: 4), Text('Tap + to add your first secret', style: TextStyle(color: Colors.white24, fontSize: 13))])),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: const Color(0xFFF0D25A), child: const Icon(Icons.add, color: Color(0xFF0F1226))),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const SettingsScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1226),
      appBar: AppBar(title: const Text('Settings', style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(leading: const Icon(Icons.timer, color: Colors.white), title: const Text('Inactivity Timer', style: TextStyle(color: Colors.white)), subtitle: const Text('Configure timer duration', style: TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_right, color: Colors.white54), onTap: () {}),
        ListTile(leading: const Icon(Icons.people, color: Colors.white), title: const Text('Manage Heirs', style: TextStyle(color: Colors.white)), subtitle: const Text('Add or remove heirs', style: TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_right, color: Colors.white54), onTap: () {}),
        ListTile(leading: const Icon(Icons.security, color: Colors.white), title: const Text('Change PIN', style: TextStyle(color: Colors.white)), subtitle: const Text('Update your security PIN', style: TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_right, color: Colors.white54), onTap: () {}),
        ListTile(leading: const Icon(Icons.vpn_key, color: Colors.white), title: const Text('2FA', style: TextStyle(color: Colors.white)), subtitle: const Text('Two-factor authentication', style: TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_right, color: Colors.white54), onTap: () {}),
        const Divider(color: Colors.white24),
        ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Lock Vault', style: TextStyle(color: Colors.red)), onTap: () {}),
      ]),
    );
  }
}
