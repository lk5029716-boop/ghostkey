import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;

const Color kSurface = Color(0xFFF8F9FA);
const Color kOnSurface = Color(0xFF191C1D);
const Color kSurfaceContainer = Color(0xFFF3F4F5);
const Color kSurfaceContainerLow = Color(0xFFF3F4F5);
const Color kSurfaceContainerHigh = Color(0xFFE1E3E4);
const Color kSurfaceContainerHighest = Color(0xFFE1E3E4);
const Color kPrimary = Color(0xFF0D631B);
const Color kOnPrimary = Colors.white;
const Color kSecondary = Color(0xFF2A6B2C);
const Color kOnSecondary = Colors.white;
const Color kSecondaryContainer = Color(0xFFACF4A4);
const Color kOnSecondaryContainer = Color(0xFF002203);
const Color kOutlineVariant = Color(0xFFBFCABA);
const Color kOutline = Color(0xFF707A6C);
const Color kSurfaceVariant = Color(0xFFE1E3E4);
const Color kOnSurfaceVariant = Color(0xFF40493D);
const Color kError = Color(0xFFBA1A1A);

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
          brightness: Brightness.light,
          scaffoldBackgroundColor: kSurface,
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: kOnPrimary,
            secondary: kSecondary,
            onSecondary: kOnSecondary,
            secondaryContainer: kSecondaryContainer,
            onSecondaryContainer: kOnSecondaryContainer,
            surface: kSurface,
            onSurface: kOnSurface,
            surfaceVariant: kSurfaceVariant,
            onSurfaceVariant: kOnSurfaceVariant,
            outline: kOutline,
            outlineVariant: kOutlineVariant,
            error: kError,
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
      backgroundColor: const Color(0xFF0F1226),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, size: 56, color: kOnPrimary),
            ),
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
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 128, height: 128, decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.withOpacity(0.1), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.15), blurRadius: 40, spreadRadius: 20)]), child: const Icon(Icons.shield, size: 72, color: kPrimary)),
                const SizedBox(height: 32),
                const Text('GhostKey', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kOnSurface, letterSpacing: -0.25)),
                const SizedBox(height: 8),
                const Text('Your digital legacy secured.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: kOnSurfaceVariant, letterSpacing: 0.5)),
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
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () { Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PinSetupScreen())); },
                style: FilledButton.styleFrom(backgroundColor: kPrimary, foregroundColor: kOnPrimary, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 4),
                child: const Text('Get started', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              )),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
                GestureDetector(onTap: () {}, child: const Text('Sign in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kPrimary))),
              ]),
              const SizedBox(height: 32),
              FractionallySizedBox(widthFactor: 1 / 3, child: Container(height: 4, decoration: BoxDecoration(color: kOutlineVariant, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 8),
            ]),
          ),
        ]),
      ),
    );
  }

  static Widget _feat(IconData icon, String label) {
    return Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 18, color: kPrimary)),
      const SizedBox(width: 16),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurfaceVariant)),
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
      if (key == 'del') { if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1); } 
      else if (_pin.length < 6) { _pin += key; }
    });
    if (_pin.length == 6) {
      if (!_confirming) { _firstPin = _pin; _pin = ''; setState(() => _confirming = true); } 
      else if (_pin == _firstPin) { context.read<SharedPreferences>().setString('pin', _pin); Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell())); } 
      else { _pin = ''; setState(() => _confirming = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match.'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(backgroundColor: kSurface, elevation: 0, leading: _confirming ? IconButton(icon: const Icon(Icons.arrow_back, color: kOnSurface), onPressed: () { setState(() { _confirming = false; _pin = ''; }); }) : null, title: Text(_confirming ? 'Confirm PIN' : 'Create PIN', style: const TextStyle(color: kOnSurface))),
      body: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_confirming ? 'Re-enter your 6-digit PIN' : 'Create a 6-digit PIN', style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) => AnimatedContainer(duration: const Duration(milliseconds: 150), width: 18, height: 18, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? kPrimary : kSurfaceContainerHighest)))),
          const SizedBox(height: 48),
          _buildKeypad(),
        ]),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = ['1','2','3','4','5','6','7','8','9','del','0','ok'];
    return SizedBox(width: 260, child: GridView.count(shrinkWrap: true, crossAxisCount: 3, childAspectRatio: 1.6, mainAxisSpacing: 8, crossAxisSpacing: 8, children: keys.map((k) {
      if (k == 'ok') return const SizedBox.shrink();
      return TextButton(onPressed: () => _onKeyTap(k), style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: k == 'del' ? const Icon(Icons.backspace_outlined, color: kOnSurface, size: 22) : Text(k, style: const TextStyle(fontSize: 26, color: kOnSurface)));
    }).toList()));
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _pages = const [VaultDashboard(), VaultPage(), HeirsPage(), _ActivityPlaceholder(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                if (_currentIndex == 1) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddSecretPage()));
                }
              },
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: kOnPrimary, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: kSurfaceContainer,
        indicatorColor: kSecondaryContainer,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home, color: kPrimary), label: 'Home'),
          NavigationDestination(icon: const Icon(Icons.lock_outlined), selectedIcon: const Icon(Icons.lock, color: kPrimary), label: 'Vault'),
          NavigationDestination(icon: const Icon(Icons.group_outlined), selectedIcon: const Icon(Icons.group, color: kPrimary), label: 'Heirs'),
          NavigationDestination(icon: const Icon(Icons.notifications_outlined), selectedIcon: const Icon(Icons.notifications, color: kPrimary), label: 'Activity'),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings, color: kPrimary), label: 'Settings'),
        ],
      ),
    );
  }
}

class _ActivityPlaceholder extends StatelessWidget {
  const _ActivityPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: kSurface, body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.notifications, size: 64, color: kOutlineVariant), const SizedBox(height: 16), const Text('Activity \u2014 coming soon', style: TextStyle(color: kOnSurfaceVariant, fontSize: 16))])));
  }
}

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});
  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  String _selectedFilter = 'All';
  final _filters = ['All', 'Passwords', 'Seeds', 'API Keys', 'Codes'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.menu, color: kPrimary, size: 24), const SizedBox(width: 12), Text('GhostKey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kPrimary))]), Container(width: 32, height: 32, decoration: BoxDecoration(color: kSurfaceContainerHigh, shape: BoxShape.circle), child: const Icon(Icons.person, color: kOnSurfaceVariant, size: 18))])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Vault', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kOnSurface)), IconButton(onPressed: () {}, icon: const Icon(Icons.create_new_folder, color: kOnSurfaceVariant))])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: kSurfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSurfaceContainerHighest)), child: Row(children: [const Icon(Icons.search, color: kOnSurfaceVariant, size: 20), const SizedBox(width: 12), const Expanded(child: TextField(style: TextStyle(color: kOnSurface, fontSize: 14), decoration: InputDecoration(hintText: 'Search secrets', hintStyle: TextStyle(color: kOnSurfaceVariant, fontSize: 14), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)))]))),
          SizedBox(height: 44, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filters.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, index) { final f = _filters[index]; final isActive = f == _selectedFilter; return GestureDetector(onTap: () => setState(() => _selectedFilter = f), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isActive ? kPrimary : kSurfaceContainer, borderRadius: BorderRadius.circular(20), border: isActive ? null : Border.all(color: kSurfaceContainerHighest)), alignment: Alignment.center, child: Text(f, style: TextStyle(color: isActive ? kOnPrimary : kOnSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)))); })),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: 6, separatorBuilder: (_, __) => Container(margin: const EdgeInsets.only(left: 56), height: 1, color: kSurfaceContainerHighest), itemBuilder: (context, index) {
            final icons = [Icons.vpn_key, Icons.currency_bitcoin, Icons.memory, Icons.dialpad, Icons.play_circle_fill, Icons.vpn_key];
            final titles = ['Google Account', 'Binance Account', 'Ledger Seed Phrase', 'AWS Root Key', 'Recovery Codes', 'Crypto.com API'];
            final subs = ['alex@gmail.com', 'alex@gmail.com', '24 words', 'AKIA....EXAMPLE', '8 codes', 'Read-only'];
            final dates = ['May 28, 2024', 'May 27, 2024', 'May 26, 2024', 'May 26, 2024', 'May 25, 2024', 'May 24, 2024'];
            return InkWell(
              onTap: () {
                if (index == 2) { // Ledger Seed Phrase
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LedgerScreen()));
                }
              },
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: kSurfaceContainer, shape: BoxShape.circle), child: Icon(icons[index], size: 20, color: kOnSurfaceVariant)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titles[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kOnSurface)), const SizedBox(height: 2), Text(subs[index], style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant))])), const SizedBox(width: 8), Text(dates[index], style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant)), const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 16, color: kOutlineVariant)])),
            );
          })),
        ]),
      ),
    );
  }
}

// Ledger Screen - matches HTML design

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  bool _revealed = false;
  int _timer = 30;
  Timer? _t;

  final List<String> _words = List.generate(24, (i) => 'word${i + 1}');

  // Color constants from HTML design
  static const Color kBackground = Color(0xFFF8F9FA);
  static const Color kSurface = Color(0xFFF8F9FA);
  static const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color kSurfaceContainerLow = Color(0xFFF3F4F5);
  static const Color kSurfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color kSurfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color kPrimary = Color(0xFF0D631B);
  static const Color kOnPrimary = Color(0xFFFFFFFF);
  static const Color kOnSurface = Color(0xFF191C1D);
  static const Color kOnSurfaceVariant = Color(0xFF40493D);
  static const Color kSecondaryContainer = Color(0xFFACF4A4);
  static const Color kOnSecondaryContainer = Color(0xFF002203);
  static const Color kOutlineVariant = Color(0xFFBFCABA);
  static const Color kError = Color(0xFFBA1A1A);
  static const Color kErrorContainer = Color(0xFFFFDAD6);
  static const Color kOnErrorContainer = Color(0xFF93000A);
  static const Color kWarning = Color(0xFFF59E0B);

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _reveal() {
    setState(() {
      _revealed = true;
      _timer = 30;
    });
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) {
        timer.cancel();
        if (mounted) setState(() => _revealed = false);
      }
    });
  }

  double get _progress => _revealed ? (30 - _timer) / 30 : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kOnSurfaceVariant, size: 24),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: kSurfaceContainerLow,
            shape: const CircleBorder(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: kOnSurfaceVariant, size: 24),
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: kSurfaceContainerLow,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Hero Icon & Title
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kSecondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key, size: 48, color: kOnSecondaryContainer),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ledger Seed Phrase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kOnSurface, height: 32/24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Seed Phrase',
              style: TextStyle(fontSize: 14, color: kOnSurfaceVariant, height: 20/14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Blurred Secret Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kSurfaceContainerHighest),
              ),
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _revealed
                        ? GridView.count(
                            key: const ValueKey('revealed'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: _words.map((w) => Center(
                              child: Text(w, style: const TextStyle(fontSize: 16, color: kOnSurface, fontWeight: FontWeight.w400)),
                            )).toList(),
                          )
                        : GridView.count(
                            key: const ValueKey('blurred'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: _words.map((w) => Center(
                              child: Text(w, style: const TextStyle(fontSize: 16, color: kOnSurface, fontWeight: FontWeight.w400)),
                            )).toList(),
                          ),
                  ),
                  if (!_revealed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: kSurfaceContainerLowest.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: _reveal,
                            icon: const Icon(Icons.visibility, size: 20, color: kOnSecondaryContainer),
                            label: const Text('Reveal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSecondaryContainer, letterSpacing: 0.1)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kSecondaryContainer,
                              foregroundColor: kOnSecondaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              elevation: 1,
                              shadowColor: Colors.black26,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Warning Message
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: kWarning),
                const SizedBox(width: 8),
                Text(
                  'Make sure no one is watching your screen.',
                  style: TextStyle(fontSize: 12, color: kWarning, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Actions List
            Container(
              decoration: BoxDecoration(
                color: kSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kSurfaceContainerHighest),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kSurfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: const Text(
                      'Actions',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: kOnSurfaceVariant, textBaseline: TextBaseline.alphabetic),
                    ),
                  ),
                  _actionTile(Icons.content_copy_outlined, 'Copy to clipboard', () {
                    Clipboard.setData(ClipboardData(text: _words.join(' ')));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  }),
                  const Divider(height: 1, thickness: 1, color: kSurfaceContainerHighest, indent: 56, endIndent: 16),
                  _actionTile(Icons.upload_outlined, 'Export', () {}),
                  const Divider(height: 1, thickness: 1, color: kSurfaceContainerHighest, indent: 56, endIndent: 16),
                  _actionTile(Icons.edit_outlined, 'Edit', () {}),
                  const Divider(height: 1, thickness: 1, color: kSurfaceContainerHighest, indent: 56, endIndent: 16),
                  _actionTile(Icons.delete_outlined, 'Delete', () {}, isError: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Auto-hide Timer
            AnimatedOpacity(
              opacity: _revealed ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: kOnSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Auto-hide in $_timer s', style: TextStyle(fontSize: 12, color: kOnSurfaceVariant, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: _progress,
                        backgroundColor: kSurfaceContainerHigh,
                        progressColor: kPrimary,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {bool isError = false}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isError ? kError : kOnSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: isError ? kError : kOnSurface))),
            Icon(Icons.chevron_right, size: 20, color: isError ? kError : kOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    
    // Background circle
    canvas.drawCircle(center, radius, Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round);
    
    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // -90 degrees (start at top)
      2 * 3.14159 * progress,
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) => old.progress != progress;
}

class HeirsPage extends StatelessWidget {
  const HeirsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('Heirs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kPrimary))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Heirs', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kOnSurface)), const SizedBox(height: 4), const Text('Add trusted people who can inherit your assets', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant))])),
          const SizedBox(height: 24),
          Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: 3, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
            final names = ['Sarah Ahmed', 'Ahmed Rahman', 'John Smith'];
            final relations = ['Sister', 'Brother', 'Lawyer'];
            final shares = ['2/5 shares', '1/5 shares', '1/5 shares'];
            final avatars = ['S', 'A', 'J'];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kOutlineVariant.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: kSurfaceContainer, shape: BoxShape.circle), child: Center(child: Text(avatars[index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kOnSurfaceVariant)))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(names[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kOnSurface)),
                    const SizedBox(height: 2),
                    Text('${relations[index]}  \u2022  ${shares[index]}', style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
                  ])),
                  const SizedBox(width: 8),
                  const Icon(Icons.mail_outlined, color: kOnSurfaceVariant, size: 20),
                  const SizedBox(width: 4),
                  const Icon(Icons.more_vert, color: kOnSurfaceVariant, size: 20),
                ],
              ),
            );
          })),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, kSurface.withOpacity(0.9), kSurface], stops: const [0.0, 0.3, 1.0])), child: SafeArea(top: false, child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 20), label: const Text('Add Heir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), style: FilledButton.styleFrom(backgroundColor: kPrimary, foregroundColor: kOnPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))))),
        ]),
      ),
    );
  }
}

class AddSecretPage extends StatelessWidget {
  const AddSecretPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _AddSecretItem(icon: Icons.lock, iconColor: const Color(0xFF1976D2), bgColor: const Color(0xFFBBDEFB), title: 'Password', subtitle: 'Store website or app passwords'),
      _AddSecretItem(icon: Icons.key, iconColor: kPrimary, bgColor: const Color(0xFFC8E6C9), title: 'Seed Phrase', subtitle: 'Store crypto seed phrases'),
      _AddSecretItem(icon: Icons.vpn_key, iconColor: const Color(0xFFF57C00), bgColor: const Color(0xFFFFE0B2), title: 'Private Key', subtitle: 'Store private keys'),
      _AddSecretItem(icon: Icons.code, iconColor: const Color(0xFF7B1FA2), bgColor: const Color(0xFFE1BEE7), title: 'API Key', subtitle: 'Store API keys (read-only)'),
      _AddSecretItem(icon: Icons.grid_view, iconColor: const Color(0xFFC2185B), bgColor: const Color(0xFFF8BBD0), title: 'Recovery Code', subtitle: 'Store backup codes'),
      _AddSecretItem(icon: Icons.description, iconColor: const Color(0xFF00796B), bgColor: const Color(0xFFB2DFDB), title: 'Secure Note', subtitle: 'Store encrypted notes or docs'),
    ];

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: kOnSurface),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            const Text('Add Secret', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kOnSurface)),
            const SizedBox(height: 4),
            const Text('Select the type of secret you want to add', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
            const SizedBox(height: 24),
            ...items.map((item) => _buildItem(context, item)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _AddSecretItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSurfaceContainerHigh),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurface)),
                const SizedBox(height: 2),
                Text(item.subtitle, style: const TextStyle(fontSize: 13, color: kOnSurfaceVariant)),
              ])),
              const Icon(Icons.chevron_right, size: 20, color: kOutlineVariant),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AddSecretItem {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  _AddSecretItem({required this.icon, required this.iconColor, required this.bgColor, required this.title, required this.subtitle});
}

class VaultDashboard extends StatefulWidget {
  const VaultDashboard({super.key});
  @override
  State<VaultDashboard> createState() => _VaultDashboardState();
}

class _VaultDashboardState extends State<VaultDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('GhostKey', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kOnSurface)), Stack(children: [const Icon(Icons.notifications_outlined, size: 28, color: kOnSurface), Positioned(right: 2, top: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: kError, shape: BoxShape.circle)))])]),
          const SizedBox(height: 24),
          const Text('Good morning,', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
          const Text('Alex \u{1F44B}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kOnSurface)),
          const SizedBox(height: 24),
          _buildDeadManCard(),
          const SizedBox(height: 16),
          Row(children: [_statCard('34', 'Secrets'), const SizedBox(width: 12), _statCard('12', 'Crypto Assets'), const SizedBox(width: 12), _statCard('3', 'Heirs')]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kOnSurface)), TextButton(onPressed: () {}, child: const Text('View all', style: TextStyle(color: kPrimary, fontSize: 12)))]),
          const SizedBox(height: 8),
          _buildActivityList(),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildDeadManCard() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: kOutlineVariant.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Dead Man's Switch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kOnSurface)), const SizedBox(height: 4), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [const Text('65', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kPrimary)), const SizedBox(width: 4), const Text('days left', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant))]), const SizedBox(height: 4), const Text('Next check-in: Tomorrow', style: TextStyle(fontSize: 12, color: kOnSurfaceVariant)), const SizedBox(height: 12), OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(side: const BorderSide(color: kPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Check in now', style: TextStyle(color: kPrimary, fontSize: 14)))])),
      const SizedBox(width: 16),
      SizedBox(width: 96, height: 96, child: CustomPaint(painter: _ProgressRing(0.65), child: const Center(child: Text('65%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kOnSurface))))),
    ]));
  }

  Widget _statCard(String value, String label) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kOutlineVariant.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]), child: Column(children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kOnSurface)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant), textAlign: TextAlign.center)])));
  }

  Widget _buildActivityList() {
    return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: kOutlineVariant.withOpacity(0.3))), child: Column(children: [
      _activityRow(Icons.vpn_key, 'Secret viewed', 'Google Account', 'Today, 9:20 AM', kOnSurfaceVariant),
      const Divider(color: kSurfaceContainerHighest, height: 1),
      _activityRow(Icons.verified_user, 'Check-in successful', '', 'Today, 9:00 AM', kPrimary),
      const Divider(color: kSurfaceContainerHighest, height: 1),
      _activityRow(Icons.person_add, 'Heir added: Sarah', '', 'Yesterday, 3:15 PM', kOnSurfaceVariant),
    ]));
  }

  Widget _activityRow(IconData icon, String title, String subtitle, String time, Color iconColor) {
    return Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: kSurfaceContainer, shape: BoxShape.circle), child: Icon(icon, size: 20, color: iconColor)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurface)), if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant))])), Text(time, style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant))]));
  }
}

class _ProgressRing extends CustomPainter {
  final double progress;
  _ProgressRing(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    canvas.drawCircle(center, radius, Paint()..color = kSurfaceContainerHighest..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, Paint()..color = kPrimary..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant _ProgressRing old) => old.progress != progress;
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
    final primary = kPrimary;
    final onSurface = kOnSurface;
    final onSurfaceVar = kOnSurfaceVariant;
    final surface = kSurface;
    final surfaceContainer = kSurfaceContainer;
    final outlineVar = kOutlineVariant;
    final error = kError;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
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
              backgroundColor: kSecondaryContainer,
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
            _row(Icons.verified_user, 'Security Audit', trailing: Icon(Icons.warning, color: error, size: 20)),
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
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[900],
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
