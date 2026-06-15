import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/ledger_screen.dart';
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
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F1226),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1226),
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
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
      backgroundColor: const Color(0xFF0F1226),
      body: SafeArea(
        child: Column(children: [
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
                  _feat(Icons.shield, 'Secure inheritance'),
                ])),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              SizedBox(width: double.infinity,
                child: FilledButton(
                  onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PinSetupScreen())); },
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
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  bool _confirming = false;
  String _firstPin = '';

  void _onKeyTap(String key) {
    setState(() {
      if (key == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 6) {
        _pin += key;
      }
    });

    if (_pin.length == 6) {
      if (!_confirming) {
        _firstPin = _pin;
        _pin = '';
        setState(() => _confirming = true);
      } else if (_pin == _firstPin) {
        final prefs = context.read<SharedPreferences>();
        prefs.setString('pin', _pin);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VaultDashboard()),
        );
      } else {
        _pin = '';
        setState(() => _confirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _confirming
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _confirming = false;
                    _pin = '';
                  });
                },
              )
            : null,
        title: Text(_confirming ? 'Confirm PIN' : 'Create PIN'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _confirming ? 'Re-enter your 6-digit PIN' : 'Create a 6-digit PIN to secure your vault',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? const Color(0xFFF0D25A)
                        : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'del', '0', 'ok'];
    return SizedBox(
      width: 260,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: keys.map((k) {
          if (k == 'ok') return const SizedBox.shrink();
          return TextButton(
            onPressed: () => _onKeyTap(k),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: k == 'del'
                ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 22)
                : Text(
                    k,
                    style: const TextStyle(fontSize: 26, color: Colors.white),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class VaultDashboard extends StatefulWidget {
  const VaultDashboard({super.key});

  @override
  State<VaultDashboard> createState() => _VaultDashboardState();
}

class _VaultDashboardState extends State<VaultDashboard> {
  int _daysRemaining = 45;
  final List<Map<String, String>> _secrets = [
    {'type': 'ledger', 'title': 'Ledger Seed Phrase', 'description': '2025-06-15'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vault'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _secrets.isEmpty ? _buildEmptyState() : _buildSecretList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LedgerScreen()),
        );
        },
        backgroundColor: const Color(0xFFF0D25A),
        child: const Icon(Icons.add, color: Color(0xFF0F1226)),
      ),
    );
  }

  void _openSecret(Map<String, String> secret) {
    if (secret['type'] == 'ledger') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LedgerScreen()),
      );
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Timer card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2040),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0D25A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer, color: Color(0xFF0F1226)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inactivity Timer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_daysRemaining days remaining',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _daysRemaining = 45);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Timer reset!')),
                  );
                },
                child: const Text('Check-in', style: TextStyle(color: Color(0xFFF0D25A))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Heirs card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2040),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF1C2040),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, color: Color(0xFFF0D25A)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heirs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('No heirs added', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Heir management — coming soon')),
                  );
                },
                child: const Text('Add', style: TextStyle(color: Color(0xFFF0D25A))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Demo Ledger secret (tappable)
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LedgerScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151833),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1C2040)),
            ),
            child: Row(
              children: const [
                Icon(Icons.key, color: Color(0xFFF0D25A)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ledger Seed Phrase', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('2025-06-15', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.lock, size: 14, color: Colors.white30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecretList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Timer card (compact)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2040),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Color(0xFFF0D25A)),
              const SizedBox(width: 12),
              Expanded(child: Text('$_daysRemaining days remaining')),
              TextButton(
                onPressed: () => setState(() => _daysRemaining = 45),
                child: const Text('Check-in', style: TextStyle(color: Color(0xFFF0D25A))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Secrets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._secrets.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF151833),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1C2040)),
              ),
              child: InkWell(
                onTap: () => _openSecret(s),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: Color(0xFFF0D25A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(s['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock, size: 14, color: Colors.white30),
                ],
              ),
            )),

      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometric = true;
  bool _emergencyAlerts = true;
  bool _checkinReminders = true;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outlineVar = Theme.of(context).colorScheme.outlineVariant;
    final error = Theme.of(context).colorScheme.error;
    final errorContainer = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainer = Theme.of(context).colorScheme.onErrorContainer;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.shield, size: 24, color: primary),
        ),
        title: Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primary)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(Icons.person, size: 18, color: onSurface),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          // Pro card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineVar.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('GhostKey Pro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface)),
                Text('Active until Oct 2025', style: TextStyle(fontSize: 14, color: onSurfaceVar)),
              ])),
              Icon(Icons.chevron_right, color: primary),
            ]),
          ),
          const SizedBox(height: 24),

          // Security section
          _sectionHeader('Security', primary),
          const SizedBox(height: 8),
          _card([
            _switchRow(Icons.fingerprint, 'Biometric Lock', _biometric, (v) => setState(() => _biometric = v)),
            _divider(outlineVar),
            _row(Icons.vpn_key, 'Change Master Password', chevron: true),
            _divider(outlineVar),
            _row(Icons.vibration, 'Two-Factor Authentication (2FA)', trailing: Text('Enabled', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w500))),
            _divider(outlineVar),
            _row(Icons.verified_user, 'SecurityAudit', trailing: Icon(Icons.warning, color: error, size: 20)),
          ]),
          const SizedBox(height: 24),

          // Vault & Timer section
          _sectionHeader('Vault & Timer', primary),
          const SizedBox(height: 8),
          _card([
            _row(Icons.alarm_on, "Dead Man's Switch Duration", trailing: Text('6 Months', style: TextStyle(fontSize: 14, color: onSurfaceVar))),
            _divider(outlineVar),
            _row(Icons.update, 'Check-in Frequency', trailing: Text('Monthly', style: TextStyle(fontSize: 14, color: onSurfaceVar))),
            _divider(outlineVar),
            _row(Icons.ios_share, 'Data Export (Encrypted)', trailing: Icon(Icons.download, color: onSurfaceVar, size: 20)),
          ]),
          const SizedBox(height: 24),

          // Notifications section
          _sectionHeader('Notifications', primary),
          const SizedBox(height: 8),
          _card([
            _switchRow(Icons.emergency, 'Emergency Alerts', _emergencyAlerts, (v) => setState(() => _emergencyAlerts = v)),
            _divider(outlineVar),
            _switchRow(Icons.event_available, 'Check-in Reminders', _checkinReminders, (v) => setState(() => _checkinReminders = v)),
          ]),
          const SizedBox(height: 24),

          // Account & Plan section
          _sectionHeader('Account & Plan', primary),
          const SizedBox(height: 8),
          _card([
            _row(Icons.credit_card, 'Payment Methods', chevron: true),
            _divider(outlineVar),
            _row(Icons.person, 'Manage Account', chevron: true),
          ]),
          const SizedBox(height: 24),

          // About section
          _sectionHeader('About', primary),
          const SizedBox(height: 8),
          _card([
            _row(Icons.policy, 'Privacy Policy', trailing: Icon(Icons.open_in_new, color: onSurfaceVar, size: 18)),
            _divider(outlineVar),
            _row(Icons.gavel, 'Terms of Service', trailing: Icon(Icons.open_in_new, color: onSurfaceVar, size: 18)),
            _divider(outlineVar),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Version 1.0.4', style: TextStyle(fontSize: 12, color: onSurfaceVar)),
                Text('Stable Release', style: TextStyle(fontSize: 12, color: onSurfaceVar)),
              ]),
            ),
          ]),
          const SizedBox(height: 24),

          // Sign Out
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (r) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorContainer,
                foregroundColor: onErrorContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout, size: 20),
                const SizedBox(width: 8),
                Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('© 2024 GhostKey Security. All rights reserved.', style: TextStyle(fontSize: 12, color: onSurfaceVar.withOpacity(0.6)))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color, letterSpacing: 0.1)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFCABA).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, thickness: 1, color: color.withOpacity(0.1), indent: 56);
  }

  Widget _row(IconData icon, String title, {Widget? trailing, bool chevron = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: const Color(0xFF40493D)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF191C1D)))),
          trailing ?? (chevron ? const Icon(Icons.chevron_right, color: Color(0xFF40493D)) : const SizedBox.shrink()),
        ]),
      ),
    );
  }

  Widget _switchRow(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(icon, size: 22, color: const Color(0xFF40493D)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF191C1D)))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2e7d32),
          activeTrackColor: const Color(0xFF2e7d32).withOpacity(0.3),
        ),
      ]),
    );
  }
}