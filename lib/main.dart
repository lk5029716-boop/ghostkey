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
            const SizedBox(height: 8),
            const Text('Your digital executor', style: TextStyle(color: Colors.white54)),
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
  final List<Map<String, String>> _secrets = [];

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add secret — coming soon')),
          );
        },
        backgroundColor: const Color(0xFFF0D25A),
        child: const Icon(Icons.add, color: Color(0xFF0F1226)),
      ),
    );
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
        const SizedBox(height: 32),
        // Empty secrets
        const Center(
          child: Column(
            children: [
              Icon(Icons.lock_open, size: 56, color: Colors.white24),
              SizedBox(height: 12),
              Text('No secrets yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
              SizedBox(height: 4),
              Text('Tap + to add your first secret', style: TextStyle(color: Colors.white30, fontSize: 13)),
            ],
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Inactivity Timer'),
            subtitle: const Text('Configure timer duration'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Heirs'),
            subtitle: const Text('Add or remove heirs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your security PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('2FA'),
            subtitle: const Text('Two-factor authentication'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Lock Vault', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (r) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}