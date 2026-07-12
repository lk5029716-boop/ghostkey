import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'vault_data.dart';
import 'vault_screens.dart';
import 'qr_scanner_screen.dart';
import 'pin_unlock_screen.dart' show PinScreen, PinScreenMode;
import 'seed_phrase_restore_screen.dart';
import 'crypto/bip39.dart';
import 'screens/password_add_screen.dart';
import 'screens/api_key_add_screen.dart';
import 'screens/recovery_codes_add_screen.dart';
import 'screens/secure_note_add_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/security_setup_screen.dart';
import 'services/preference_service.dart';
import 'services/seed_phrase_storage.dart';
import 'ui/settings/data_section_widget.dart';
import 'ui/utils/icon_utils.dart';
import 'ui/code_widget.dart';
import 'ui/reorder_codes_page.dart';
import 'ui/home/coach_mark_widget.dart';
import 'store/code_store.dart';
import 'store/vault_store.dart';
import 'events/vault_items_updated_event.dart';
import 'events/codes_updated_event.dart';
import 'services/quick_add_service.dart';
import 'services/quick_add_service.dart';
import 'models/code.dart';
import 'models/code_display.dart';
import 'screens/openrouter_test_screen.dart';
import 'ui/home/vault_home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const Color kSurface = Color(0xFFF4F3FF); // surface-dim (body bg)
const Color kOnSurface = Color(0xFF12101E);
const Color kSurfaceContainer = Color(0xFFFFFFFF); // surface (nav bar bg)
const Color kSurfaceContainerLow = Color(0xFFF6F1FF);
const Color kSurfaceContainerHigh = Color(0xFFEBE6F4);
const Color kSurfaceContainerHighest = Color(0xFFE5E0EE);
const Color kPrimary = Color(0xFF5B3FE8);
const Color kOnPrimary = Colors.white;
const Color kSecondary = Color(0xFF5D5E68);
const Color kOnSecondary = Colors.white;
const Color kSecondaryContainer = Color(0xFFE2E1ED);
const Color kOnSecondaryContainer = Color(0xFF63646E);
const Color kOutlineVariant = Color(0xFFE4E2F5);
const Color kOutline = Color(0xFF787587);
const Color kSurfaceVariant = Color(0xFFE5E0EE);
const Color kOnSurfaceVariant = Color(0xFF8E8BA8);
const Color kError = Color(0xFFBA1A1A);
const Color kWarning = Color(0xFFF59E0B);
const Color kPrimaryContainer = Color(0xFFEBE8FF);
const Color kSurfaceDim = Color(0xFFF4F3FF);
const Color kSurfaceBright = Color(0xFFFCF8FF);
const Color kTertiary = Color(0xFF7D3100);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await PreferenceService.instance.init();
  // Heavy inits block runApp() on purpose. The Android launch drawable
  // (green shield on light gradient) stays on screen the whole time,
  // then Flutter takes over directly to the home tab. No custom Flutter
  // splash, no animations — matches ente.
  try {
    await Future.wait([
      BrandIconRegistry.instance.init(),
      CodeStore.instance.init(),
      Bip39Validator.loadWordlist(),
      VaultStore.instance.database, // create vault DB if not exists
    ]);

    // Seed demo data if vault is empty
    await _seedDemoDataIfNeeded();
  } catch (e, st) {
    debugPrint('Init failed: $e\n$st');
  }
  runApp(GhostKeyApp(prefs: prefs));
}

/// Seed demo vault items on first launch only.
Future<void> _seedDemoDataIfNeeded() async {
  // Disabled — user wants real data only, not demo
  return;
}

class GhostKeyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const GhostKeyApp({super.key, required this.prefs});

  @override
  State<GhostKeyApp> createState() => _GhostKeyAppState();
}

class _GhostKeyAppState extends State<GhostKeyApp> {
  @override
  Widget build(BuildContext context) {
    return Provider<SharedPreferences>.value(
      value: widget.prefs,
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'GhostKey',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: kSurface,
          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: kOnPrimary,
            primaryContainer: kPrimaryContainer,
            secondary: kSecondary,
            onSecondary: kOnSecondary,
            secondaryContainer: kSecondaryContainer,
            onSecondaryContainer: kOnSecondaryContainer,
            tertiary: kTertiary,
            surface: kSurface,
            onSurface: kOnSurface,
            surfaceVariant: kSurfaceVariant,
            onSurfaceVariant: kOnSurfaceVariant,
            outline: kOutline,
            outlineVariant: kOutlineVariant,
            error: kError,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: kSurface,
            foregroundColor: kOnSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w700, color: kOnSurface, letterSpacing: -0.01),
            iconTheme: const IconThemeData(color: kOnSurface),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: BorderSide(color: kOutlineVariant),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: kPrimary,
              textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 2,
            shadowColor: kPrimary.withOpacity(0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          dialogTheme: DialogTheme(
            backgroundColor: kSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: kOnSurface),
            contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: kOnSurfaceVariant),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kSurfaceVariant.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kOutlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kOutlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kPrimary, width: 2),
            ),
            labelStyle: GoogleFonts.plusJakartaSans(color: kOnSurfaceVariant),
            hintStyle: GoogleFonts.plusJakartaSans(color: kOnSurfaceVariant),
          ),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: kSurface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
        home: _initialHome(widget.prefs),
      ),
    );
  }

  /// Resolves the first screen to show after the Android launch drawable
  /// fades out. Mirrors what SplashScreen used to do via [resolveHome].
  Widget _initialHome(SharedPreferences prefs) {
    final hasPin = prefs.getString('pin') != null;
    final onboarded = prefs.getBool('onboarded') ?? false;
    if (!onboarded) return const OnboardingScreen();
    if (hasPin) return _unlockScreen(prefs);
    return const MainShell();
  }

  Widget _unlockScreen(SharedPreferences prefs) {
    final stored = prefs.getString('pin') ?? '';
    return PinScreen(
      title: 'Unlock GhostKey',
      subtitle: 'Use your biometric or PIN to continue',
      mode: PinScreenMode.unlock,
      expectedPin: stored,
      autoTriggerBiometric: true,
      onUnlock: (_) {
        rootNavigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      },
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    // Start after a tiny delay so the splash fade-out has room to play
    // before the onboarding content appears.
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  // M3 design tokens (matching HTML)
  static const Color _accentGreen = Color(0xFF88D982); // primary-fixed-dim

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSurface, kSurfaceContainerLow],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _opacity,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      // Hero from the splash logo — same brand mark animates
                      // across the route change so the eye is never lost.
                      Hero(
                        tag: 'ghostkey-logo',
                        child: SizedBox(
                          width: 144,
                          height: 144,
                          child: Stack(alignment: Alignment.center, children: [
                            // Outer soft radial glow
                            Container(
                              width: 144, height: 144,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [kPrimary.withOpacity(0.18), kPrimary.withOpacity(0.0)]),
                              ),
                            ),
                            // Mid ring
                            Container(
                              width: 112, height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kPrimary.withOpacity(0.06),
                                border: Border.all(color: kPrimary.withOpacity(0.12), width: 1),
                              ),
                            ),
                            // Inner badge (matches splash canvas)
                            Container(
                              width: 88, height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kSurface,
                                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.20), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Image.asset(
                                  'assets/Canvas1.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title (M3 headline)
                      const Text('GhostKey', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kOnSurface, height: 36/28, letterSpacing: -0.25)),
                      const SizedBox(height: 8),
                      // Subtitle (M3 body-large)
                      const Text('Your digital legacy secured.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: kOnSurfaceVariant, height: 24/16, letterSpacing: 0.5)),
                      const SizedBox(height: 48),
                      // Features
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
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                // Primary CTA (M3 filled, rounded-full)
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signup)),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kOnPrimary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 4,
                  ),
                  child: const Text('Get started', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1)),
                )),
                const SizedBox(height: 16),
                // Sign in link (M3 accent = primary-fixed-dim, not dark primary)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kOnSurfaceVariant, letterSpacing: 0.25)),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signin)),
                      );
                    },
                    child: const Text('Sign in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _accentGreen, letterSpacing: 0.5)),
                  ),
                ]),
                const SizedBox(height: 32),
                // Bottom indicator pill
                FractionallySizedBox(widthFactor: 1 / 3, child: Container(height: 4, decoration: BoxDecoration(color: kOutlineVariant, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 8),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // M3 spec: 32x32 circle, primary-fixed-dim icon, primary-fixed at 10-15% bg
  static Widget _feat(IconData icon, String label) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: _accentGreen.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: _accentGreen),
      ),
      const SizedBox(width: 16),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurfaceVariant, height: 20/14, letterSpacing: 0.1)),
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.read<SharedPreferences>().setBool('onboarded', true);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainShell()),
              );
            },
            child: const Text('Skip for now', style: TextStyle(color: kOnSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
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

// ═══════════════════════════════════════════════════════════════
// TOTP GENERATOR (for 2FA list items)
// ═══════════════════════════════════════════════════════════════
String _generateTOTP(String secret, {int period = 30, int digits = 6}) {
  final key = _base32Decode(secret.toUpperCase().replaceAll(' ', ''));
  if (key.isEmpty) return '------';
  final time = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ period;
  final timeBytes = Uint8List(8);
  final bd = ByteData.view(timeBytes.buffer);
  bd.setUint64(0, time, Endian.big);
  final hmac = Hmac(sha1, key);
  final hash = hmac.convert(timeBytes).bytes;
  final offset = hash[hash.length - 1] & 0x0F;
  final binary = ((hash[offset] & 0x7F) << 24) |
      ((hash[offset + 1] & 0xFF) << 16) |
      ((hash[offset + 2] & 0xFF) << 8) |
      (hash[offset + 3] & 0xFF);
  final otp = binary % _pow10(digits);
  return otp.toString().padLeft(digits, '0');
}

Uint8List _base32Decode(String input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final output = <int>[];
  int buffer = 0;
  int bitsLeft = 0;
  for (final char in input.codeUnits) {
    final idx = alphabet.codeUnits.indexOf(char);
    if (idx < 0) continue;
    buffer = (buffer << 5) | idx;
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      output.add((buffer >> bitsLeft) & 0xFF);
    }
  }
  return Uint8List.fromList(output);
}

int _pow10(int n) {
  int r = 1;
  for (int i = 0; i < n; i++) r *= 10;
  return r;
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _pages = <Widget>[
    const VaultHomeScreen(),
    VaultPage(),
    const SettingsScreen(),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        const VaultHomeScreen(),
        const VaultPage(),
        const SettingsScreen(),
      ]),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: kSurfaceContainer,
        indicatorColor: kPrimaryContainer,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home, color: kPrimary), label: 'Home'),
          NavigationDestination(icon: const Icon(Icons.lock_outlined), selectedIcon: const Icon(Icons.lock, color: kPrimary), label: 'Vault'),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings, color: kPrimary), label: 'Settings'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2FA TOTP LIST ITEM — shows live code + circular timer inline
// ═══════════════════════════════════════════════════════════════
class _TotpListItem extends StatefulWidget {
  final VaultItem item;
  const _TotpListItem({required this.item});

  @override
  State<_TotpListItem> createState() => _TotpListItemState();
}

class _TotpListItemState extends State<_TotpListItem> {
  Timer? _timer;
  String _currentCode = '';
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _generateCode();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateCode() {
    final secret = widget.item.fields['TOTP Secret'] ?? '';
    if (secret.isNotEmpty) {
      _currentCode = _generateTOTP(secret);
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _secondsLeft = 30 - (now % 30);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _generateCode();
        setState(() => _secondsLeft = 30);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (30 - _secondsLeft) / 30.0;
    final codeFormatted = _currentCode.length == 6
        ? '${_currentCode.substring(0, 3)} ${_currentCode.substring(3)}'
        : _currentCode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          // Service icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kSurfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.item.icon, size: 20, color: widget.item.iconColor),
          ),
          const SizedBox(width: 16),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kOnSurface)),
                const SizedBox(height: 2),
                Text(widget.item.subtitle, style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Live code
          Text(
            codeFormatted,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: kPrimary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 12),
          // Circular countdown timer
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(32, 32),
                  painter: _CircularProgressPainter(
                    progress: progress,
                    backgroundColor: kSurfaceContainerHighest,
                    progressColor: kPrimary,
                    strokeWidth: 3,
                  ),
                ),
                Text(
                  '${_secondsLeft}s',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kOnSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});
  @override
  State<VaultPage> createState() => _VaultPageState();
}

// ── Shared tile map: Home tab tile types → Vault category + add screen ──
class _VaultTileInfo {
  final String label;
  final IconData icon;
  final VaultCategory category;
  final WidgetBuilder builder;
  const _VaultTileInfo(this.label, this.icon, this.category, this.builder);
}
Widget _vLogin(_) => const PasswordAddScreen();
Widget _vNote(_) => const SecureNoteAddScreen();
Widget _vApi(_) => const ApiKeyAddScreen();
Widget _vRecovery(_) => const RecoveryCodesAddScreen();
Widget _vTotp(_) => const QrScannerScreen();
Widget _vSeed(_) => const SeedPhraseRestoreScreen();
const Map<HomeTileType, _VaultTileInfo> _kVaultTileInfo = {
  HomeTileType.login: _VaultTileInfo('Passwords', Icons.login, VaultCategory.password, _vLogin),
  HomeTileType.note: _VaultTileInfo('Secure Notes', Icons.note, VaultCategory.notes, _vNote),
  HomeTileType.apiKey: _VaultTileInfo('API Keys', Icons.vpn_key, VaultCategory.apiKeys, _vApi),
  HomeTileType.recoveryCodes: _VaultTileInfo('Recovery Codes', Icons.grid_view, VaultCategory.codes, _vRecovery),
  HomeTileType.totp: _VaultTileInfo('2FA Codes', Icons.shield, VaultCategory.totp, _vTotp),
  HomeTileType.seed: _VaultTileInfo('Seed Phrase', Icons.spa, VaultCategory.seeds, _vSeed),
};

/// (Vault tile grid now uses Home tab's shared tile model — see _kVaultTileInfo.)
class _VaultPageState extends State<VaultPage> {
  List<VaultItem> _vaultItems = [];
  List<Code> _codes = [];
  bool _loaded = false;
  VaultCategory? _selectedCategory; // null = tile grid; non-null = filtered list
  // shared tile grid (mirrors Home tab)
  static const _kHomeKey = 'gk_home_tiles_v1';
  static const _kVaultKey = 'gk_vault_tiles_v1';
  final _uuid = const Uuid();
  List<HomeTile> _tiles = [];
  final Set<String> _removingIds = {};
  bool _organizeMode = false;
  SharedPreferences? _prefs;
  StreamSubscription<VaultItemsUpdatedEvent>? _vaultSub;
  StreamSubscription<CodesUpdatedEvent>? _codesSub;
  StreamSubscription? _quickAddSub;


  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadTiles();
    _vaultSub = VaultStore.instance.onVaultItemsUpdated().listen((_) => _loadVaultItems());
    _codesSub = CodeStore.instance.onCodesUpdated().listen((_) => _loadCodes());
    // Listen for quick-add events from Home tab
    _quickAddSub = QuickAddService.instance.bus.on<FilterChangedEvent>().listen((event) {
      if (event is FilterChangedEvent) {
        setState(() => _selectedCategory = event.category);
      }
    });
  }

  @override
  void dispose() {
    _vaultSub?.cancel();
    _codesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadVaultItems(), _loadCodes()]);
  }

  Future<void> _loadVaultItems() async {
    try {
      final items = await VaultStore.instance.getAllItems();
      if (!mounted) return;
      setState(() {
        _vaultItems = items;
        _loaded = true;
      });
    } catch (e) {
      debugPrint('Failed to load vault items: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _loadCodes() async {
    try {
      final codes = await CodeStore.instance.getAllCodes();
      if (!mounted) return;
      setState(() {
        _codes = codes;
        _loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  /// All vault items + 2FA codes merged
  List<VaultItem> get _allVaultItems {
    final list = <VaultItem>[..._vaultItems];
    for (final c in _codes) {
      list.add(VaultItem(
        id: 'code_${c.hashCode}',
        title: c.issuer.isNotEmpty ? c.issuer : c.account,
        subtitle: c.account.isNotEmpty ? c.account : 'TOTP',
        category: VaultCategory.totp,
        icon: Icons.security,
        iconColor: kPrimary,
        iconBgColor: const Color(0xFFC8E6C9),
        date: 'Today',
        fields: {'TOTP Secret': c.secret, 'Username': c.account},
      ));
    }
    return list;
  }

  /// Items filtered by the selected category box.
  List<VaultItem> get _filteredItems {
    final cat = _selectedCategory;
    if (cat == null) return _allVaultItems;
    return _allVaultItems.where((i) => i.category == cat).toList();
  }

  bool get _isEmpty => _allVaultItems.isEmpty;

  /// Navigate to the add screen for the currently selected category.
  Future<void> _onFabPressed(BuildContext context) async {
    final cat = _selectedCategory ?? VaultCategory.password;
    Widget? page;
    switch (cat) {
      case VaultCategory.password:
        page = const PasswordAddScreen();
        break;
      case VaultCategory.seeds:
        page = const SeedPhraseRestoreScreen();
        break;
      case VaultCategory.apiKeys:
        page = const ApiKeyAddScreen();
        break;
      case VaultCategory.codes:
        page = const RecoveryCodesAddScreen();
        break;
      case VaultCategory.notes:
        page = const SecureNoteAddScreen();
        break;
      case VaultCategory.totp:
        page = const QrScannerScreen();
        break;
      case VaultCategory.privateKeys:
        return; // not implemented yet
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
    _loadVaultItems();
    _loadCodes();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory != null) return _buildListView();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FF),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VaultTopBar(
                    organizeMode: _organizeMode,
                    onDone: () => setState(() => _organizeMode = false),
                  ),
                  const SizedBox(height: 16),
                  if (!_loaded)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: kPrimary)),
                    )
                  else if (_tiles.isEmpty)
                    _VaultEmptyState()
                  else
                    _buildGrid(),
                ],
              ),
            ),
            if (!_organizeMode)
              Positioned(right: 24, bottom: 28, child: _VaultFab(onTap: _openAddSheet)),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTiles() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final raw = prefs.getString(_kVaultKey) ?? prefs.getString(_kHomeKey);
    List<HomeTile> loaded = [];
    if (raw != null) {
      try {
        loaded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(HomeTile.fromJson).toList();
      } catch (_) {
        loaded = [];
      }
    }
    if (!mounted) return;
    setState(() => _tiles = loaded);
    if (prefs.getString(_kVaultKey) == null && raw != null) _persist();
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kVaultKey, jsonEncode(_tiles.map((t) => t.toJson()).toList()));
  }

  void _addTile(HomeTileType type) {
    setState(() => _tiles.add(HomeTile(id: _uuid.v4(), type: type)));
    _persist();
  }

  Future<void> _removeTile(String id) async {
    setState(() => _removingIds.add(id));
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() {
      _tiles.removeWhere((t) => t.id == id);
      _removingIds.remove(id);
      if (_tiles.isEmpty) _organizeMode = false;
    });
    _persist();
  }

  void _reorder(int from, int to) {
    if (from == to) return;
    setState(() {
      final t = _tiles.removeAt(from);
      _tiles.insert(to, t);
    });
    _persist();
  }

  void _openTile(HomeTile tile) {
    final info = _kVaultTileInfo[tile.type]!;
    setState(() => _selectedCategory = info.category);
  }

  Future<void> _openAddSheet() async {
    final used = _tiles.map((t) => t.type).toSet();
    final available = HomeTileType.values.where((t) => !used.contains(t)).toList();
    final selected = await showModalBottomSheet<HomeTileType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _VaultAddSheet(available: available),
    );
    if (selected != null) _addTile(selected);
  }

  Widget _buildGrid() {
    return LayoutBuilder(builder: (ctx, constraints) {
      const gap = 16.0;
      final cellW = (constraints.maxWidth - gap) / 2;
      final cellH = cellW;
      final rows = _tiles.isEmpty ? 0 : ((_tiles.length - 1) ~/ 2) + 1;
      final height = rows == 0 ? 0.0 : rows * cellH + (rows - 1) * gap;
      final children = <Widget>[];
      for (int i = 0; i < _tiles.length; i++) {
        final tile = _tiles[i];
        final col = i % 2;
        final row = i ~/ 2;
        children.add(
          AnimatedPositioned(
            key: ValueKey('pos_${tile.id}'),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: col * (cellW + gap),
            top: row * (cellH + gap),
            width: cellW,
            height: cellH,
            child: _VaultTileCard(
              key: ValueKey(tile.id),
              tile: tile,
              width: cellW,
              height: cellH,
              organizeMode: _organizeMode,
              removing: _removingIds.contains(tile.id),
              index: i,
              onTap: () => _openTile(tile),
              onLongPress: () => setState(() => _organizeMode = true),
              onRemove: () => _removeTile(tile.id),
              onReorderRequested: (from) => _reorder(from, i),
            ),
          ),
        );
      }
      return SizedBox(
        height: height,
        child: Stack(clipBehavior: Clip.none, children: children),
      );
    });
  }

  /// Filtered list view shown after tapping a category box. Reuses all
  /// existing list / FAB / detail / multi-select code unchanged.
  Widget _buildListView() {
    final items = _filteredItems;
    final cat = _selectedCategory!;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FF),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kOnSurface, size: 24),
                    onPressed: () => setState(() => _selectedCategory = null),
                  ),
                  Text(_catLabel(cat), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kOnSurface)),
                ]),
                // refresh and three-dot icons removed
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (!_loaded)
            const Expanded(child: Center(child: CircularProgressIndicator(color: kPrimary)))
          else if (cat == VaultCategory.totp)
            Expanded(child: _CodesListWidget(codes: _codes))
          else if (_isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _buildCard(items[i]),
              ),
            ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onFabPressed(context),
        backgroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: kOnPrimary, size: 28),
      ),
    );
  }

  Widget _buildCard(VaultItem item) {
    return _VaultListCard(
      item: item,
      onTap: () => _openDetail(item),
    );
  }

  String _catLabel(VaultCategory cat) {
    switch (cat) {
      case VaultCategory.password: return 'Password';
      case VaultCategory.seeds: return 'Seed';
      case VaultCategory.apiKeys: return 'API Key';
      case VaultCategory.codes: return 'Code';
      case VaultCategory.totp: return '2FA';
      case VaultCategory.notes: return 'Note';
      case VaultCategory.privateKeys: return 'Key';
    }
  }

  void _openDetail(VaultItem item) {
    Widget? page;
    switch (item.category) {
      case VaultCategory.password:
        page = PasswordDetailScreen(item: item);
        break;
      case VaultCategory.seeds:
        page = SeedsDetailScreen(item: item);
        break;
      case VaultCategory.apiKeys:
        page = ApiKeysDetailScreen(item: item);
        break;
      case VaultCategory.codes:
        page = CodesDetailScreen(item: item);
        break;
      case VaultCategory.totp:
        break;
      case VaultCategory.notes:
      case VaultCategory.privateKeys:
        break;
    }
    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
    }
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: kSurfaceContainerLow, shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline, size: 32, color: kOnSurfaceVariant),
            ),
            const SizedBox(height: 20),
            const Text('Your vault is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kOnSurface)),
            const SizedBox(height: 8),
            const Text('Tap the + button to add your first secret', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// VAULT LIST CARD — item card in filtered list view
// White surface, larger square tinted icon, bold title + subtitle,
// subtle press-scale. Matches the app's color core (white card on
// light purple surface) — no chevron, no category pill.
// ════════════════════════════════════════════════
class _VaultListCard extends StatefulWidget {
  final VaultItem item;
  final VoidCallback onTap;
  const _VaultListCard({required this.item, required this.onTap});

  @override
  State<_VaultListCard> createState() => _VaultListCardState();
}

class _VaultListCardState extends State<_VaultListCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B3FE8).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: item.iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, size: 26, color: item.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF12101E),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8BA8),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// ════════════════════════════════════════════════
// VAULT TILE CARD — mirrors the Home tab tile (unified indigo),
// with long-press-to-organize, drag-to-reorder, and delete badge.
// ════════════════════════════════════════════════
const Color _cSurface = Color(0xFFFFFFFF);
const Color _cPrimary = Color(0xFF5B3FE8);
const Color _cOnSurface = Color(0xFF12101E);
TextStyle _font(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height);

class _VaultTileCard extends StatefulWidget {
  final HomeTile tile;
  final double width;
  final double height;
  final bool organizeMode;
  final bool removing;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final void Function(int fromIndex) onReorderRequested;

  const _VaultTileCard({
    super.key,
    required this.tile,
    required this.width,
    required this.height,
    required this.organizeMode,
    required this.removing,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    required this.onReorderRequested,
  });

  @override
  State<_VaultTileCard> createState() => _VaultTileCardState();
}

class _VaultTileCardState extends State<_VaultTileCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _entered = false;
  late final AnimationController _wobbleCtrl;
  late final double _wobbleSign;

  @override
  void initState() {
    super.initState();
    _wobbleSign = widget.index.isEven ? 1.0 : -1.0;
    _wobbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _wobbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _kVaultTileInfo[widget.tile.type]!;

    final cardContent = AnimatedScale(
      scale: widget.removing ? 0.0 : (_pressed ? 0.96 : (_entered ? 1.0 : 0.0)),
      duration: Duration(milliseconds: widget.removing ? 180 : 220),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: widget.removing ? 0.0 : (_entered ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 200),
        child: AnimatedBuilder(
          animation: _wobbleCtrl,
          builder: (ctx, child) {
            final angle =
                widget.organizeMode ? (_wobbleSign * 0.018 * (_wobbleCtrl.value * 2 - 1)) : 0.0;
            return Transform.rotate(angle: angle, child: child);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cSurface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: _cPrimary.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _cPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(info.icon, color: _cPrimary, size: 24),
                ),
                Text(info.label, style: _font(18, FontWeight.w700, _cOnSurface, height: 24 / 18)),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.organizeMode) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: cardContent,
      );
    }

    final withBadge = Stack(
      clipBehavior: Clip.none,
      children: [
        cardContent,
        Positioned(
          right: -6,
          top: -6,
          child: _RemoveBadge(onTap: widget.onRemove),
        ),
      ],
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != widget.index,
      onAcceptWithDetails: (details) => widget.onReorderRequested(details.data),
      builder: (ctx, candidate, rejected) => LongPressDraggable<int>(
        data: widget.index,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.06,
            child: SizedBox(width: widget.width, height: widget.height, child: cardContent),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: withBadge),
        child: withBadge,
      ),
    );
  }
}

// ── Shared chrome (indigo, matches Home tab) ─────────────────────
class _VaultTopBar extends StatelessWidget {
  final bool organizeMode;
  final VoidCallback onDone;
  const _VaultTopBar({required this.organizeMode, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xCCF4F3FF)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Vault', style: _font(12, FontWeight.w500, _cOnSurface.withOpacity(0.6))),
              const SizedBox(height: 2),
              Text('Vault', style: _font(24, FontWeight.w700, _cPrimary)),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: organizeMode
                ? _VaultPill(key: const ValueKey('done'), label: 'Done', onTap: onDone)
                : const SizedBox(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

class _VaultPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _VaultPill({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cPrimary,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(label, style: _font(14, FontWeight.w500, Colors.white)),
        ),
      ),
    );
  }
}

class _VaultFab extends StatelessWidget {
  final VoidCallback onTap;
  const _VaultFab({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _cPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}

class _VaultEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: _cPrimary.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.dashboard_customize, size: 32, color: _cPrimary),
            ),
            const SizedBox(height: 20),
            Text('No shortcuts yet', style: _font(18, FontWeight.w600, _cOnSurface)),
            const SizedBox(height: 8),
            Text('Tap the + button to add your first one', style: _font(14, FontWeight.w400, _cOnSurface.withOpacity(0.6)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveBadge({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.close, size: 16, color: Colors.red),
      ),
    );
  }
}

class _VaultAddSheet extends StatelessWidget {
  final List<HomeTileType> available;
  const _VaultAddSheet({required this.available});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(color: _cSurface, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: _cPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text('Add shortcut', style: _font(20, FontWeight.w700, _cOnSurface)),
            const SizedBox(height: 4),
            Text('Choose what to add to your Vault', style: _font(13, FontWeight.w400, _cOnSurface.withOpacity(0.6))),
            const SizedBox(height: 16),
            if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('All shortcuts are already on your Vault.', style: _font(14, FontWeight.w500, _cOnSurface.withOpacity(0.6))),
              )
            else
              ...available.map((t) {
                final info = _kVaultTileInfo[t]!;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: _cPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(info.icon, color: _cPrimary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Text(info.label, style: _font(15.5, FontWeight.w600, _cOnSurface)),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// 2FA CODES LIST — uses CodeWidget for full features
// (multi-select, reorder, brand icons, coach marks)
// ════════════════════════════════════════════════
class _CodesListWidget extends StatefulWidget {
  final List<Code> codes;
  const _CodesListWidget({required this.codes});

  @override
  State<_CodesListWidget> createState() => _CodesListWidgetState();
}

class _CodesListWidgetState extends State<_CodesListWidget> {
  bool _isMultiSelect = false;
  final Set<int> _selectedCodeHashes = {};
  StreamSubscription<CodesUpdatedEvent>? _codesSub;
  List<Code> _codes = [];

  @override
  void initState() {
    super.initState();
    _codes = List<Code>.from(widget.codes);
    _codesSub = CodeStore.instance.onCodesUpdated().listen((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant _CodesListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always sync local _codes from the new widget.codes list. Using
    // a length/content check is more reliable than reference equality
    // because the parent may pass the same list reference but with
    // updated contents in some edge cases.
    final oldLen = oldWidget.codes.length;
    final newLen = widget.codes.length;
    final changed = oldLen != newLen ||
        (newLen > 0 &&
            (oldWidget.codes.isEmpty ||
                oldWidget.codes.first.hashCode !=
                    widget.codes.first.hashCode ||
                oldWidget.codes.last.hashCode !=
                    widget.codes.last.hashCode));
    if (changed || oldWidget.codes != widget.codes) {
      _codes = List<Code>.from(widget.codes);
    }
  }

  Future<void> _refresh() async {
    final codes = await CodeStore.instance.getAllCodes();
    if (!mounted) return;
    setState(() => _codes = codes);
  }

  @override
  void dispose() {
    _codesSub?.cancel();
    super.dispose();
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelect = !_isMultiSelect;
      if (!_isMultiSelect) _selectedCodeHashes.clear();
    });
  }

  void _toggleCodeSelection(Code code) {
    setState(() {
      if (_selectedCodeHashes.contains(code.hashCode)) {
        _selectedCodeHashes.remove(code.hashCode);
        if (_selectedCodeHashes.isEmpty) _isMultiSelect = false;
      } else {
        _selectedCodeHashes.add(code.hashCode);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final selected = _codes
        .where((c) => _selectedCodeHashes.contains(c.hashCode))
        .toList();
    for (final c in selected) {
      await CodeStore.instance.removeCode(c);
    }
    if (mounted) _toggleMultiSelect();
  }

  Future<void> _bulkPin(bool pinned) async {
    final selected = _codes
        .where((c) => _selectedCodeHashes.contains(c.hashCode))
        .toList();
    for (final c in selected) {
      final updated = c.copyWith(
        display: c.display.copyWith(pinned: pinned),
      );
      await CodeStore.instance.addOrUpdateCode(updated);
    }
    if (mounted) _toggleMultiSelect();
  }

  Future<void> _openReorder() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReorderCodesPage(codes: _codes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_isMultiSelect) ...[
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleMultiSelect,
                ),
                Text(
                  '${_selectedCodeHashes.length} selected',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kOnSurface),
                ),
                const Spacer(),
              ] else ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.swap_vert, color: kOnSurfaceVariant),
                  tooltip: 'Reorder',
                  onPressed: _openReorder,
                ),
                if (_codes.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist, color: kOnSurfaceVariant),
                    tooltip: 'Select multiple',
                    onPressed: _toggleMultiSelect,
                  ),
              ],
            ],
          ),
        ),
        // Codes list
        Expanded(
          child: _codes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security, size: 56, color: kOnSurfaceVariant),
                        const SizedBox(height: 16),
                        const Text('No 2FA codes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kOnSurface)),
                        const SizedBox(height: 8),
                        const Text('Tap the + button to add your first code', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: const PageStorageKey<String>('codes_list'),
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: _codes.length,
                  itemBuilder: (context, index) {
                    final code = _codes[index];
                    final selected = _selectedCodeHashes.contains(code.hashCode);
                    return CodeWidget(
                      code,
                      key: ValueKey('code_${index}_${code.hashCode}'),
                      isSelectable: _isMultiSelect,
                      isSelected: selected,
                      onSelectionChanged: () => _toggleCodeSelection(code),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MultiSelectAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _MultiSelectAction({required this.icon, required this.label, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? kError : kOnSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
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

// ═══════════════════════════════════════════════════════════════
// Google Account Detail Screen
// ═══════════════════════════════════════════════════════════════
class GoogleAccountScreen extends StatefulWidget {
  const GoogleAccountScreen({super.key});
  @override
  State<GoogleAccountScreen> createState() => _GoogleAccountScreenState();
}

class _GoogleAccountScreenState extends State<GoogleAccountScreen> {
  bool _passwordRevealed = false;
  bool _emailRevealed = false;
  bool _backupRevealed = false;
  int _timer = 30;
  Timer? _t;

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  void _startTimer(void Function() onTimeout) {
    _t?.cancel();
    setState(() => _timer = 30);
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) { t.cancel(); if (mounted) onTimeout(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Google Account', style: TextStyle(color: kOnSurface)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: kOnSurfaceVariant), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          // Header
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.email, size: 36, color: Color(0xFF4285F4))),
            const SizedBox(height: 12),
            const Text('Google Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kOnSurface)),
            const SizedBox(height: 4), Text('alex@gmail.com', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
          ])),
          const SizedBox(height: 32),
          // Email field
          _fieldCard(
            icon: Icons.alternate_email,
            label: 'Email',
            value: 'alex@gmail.com',
            revealed: _emailRevealed,
            onReveal: () {
              setState(() => _emailRevealed = true);
              _startTimer(() => setState(() => _emailRevealed = false));
            },
          ),
          const SizedBox(height: 12),
          // Password field
          _fieldCard(
            icon: Icons.lock_outline,
            label: 'Password',
            value: 'Str0ng!P@ssw0rd#2024',
            revealed: _passwordRevealed,
            onReveal: () {
              setState(() => _passwordRevealed = true);
              _startTimer(() => setState(() => _passwordRevealed = false));
            },
            warning: true,
          ),
          const SizedBox(height: 12),
          // Backup codes
          _buildBackupCodes(),
          const SizedBox(height: 12),
          // Recovery email
          _fieldCard(
            icon: Icons.replay,
            label: 'Recovery Email',
            value: 'alex.backup@gmail.com',
            revealed: true,
            onReveal: () {},
            noBlur: true,
          ),
          const SizedBox(height: 24),
          // Timer
          if (_passwordRevealed || _emailRevealed)
            Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined, size: 16, color: kWarning),
              const SizedBox(width: 8),
              Text('Auto-hide in $_timer s', style: const TextStyle(fontSize: 12, color: kWarning, fontWeight: FontWeight.w500)),
            ])),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _fieldCard({
    required IconData icon,
    required String label,
    required String value,
    required bool revealed,
    required VoidCallback onReveal,
    bool warning = false,
    bool noBlur = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning ? kWarning.withOpacity(0.3) : kOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: warning ? kWarning : kOnSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: warning ? kWarning : kOnSurfaceVariant)),
          const Spacer(),
          if (!noBlur)
            GestureDetector(
              onTap: revealed ? null : onReveal,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(revealed ? Icons.visibility_off : Icons.visibility, size: 16, color: kPrimary),
                const SizedBox(width: 4),
                Text(revealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
              ]),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              revealed || noBlur ? value : '••••••••••••',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kOnSurface, letterSpacing: 0.5),
            ),
          ),
          if (revealed || noBlur)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
              },
              child: const Icon(Icons.copy, size: 18, color: kOnSurfaceVariant),
            ),
        ]),
      ]),
    );
  }

  Widget _buildBackupCodes() {
    final codes = ['8472-9910', '5531-0087', '2294-7763', '1108-4456', '6677-3321', '9901-5543', '3344-8899', '7755-1122'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kWarning.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.security, size: 18, color: kWarning),
          const SizedBox(width: 8),
          const Text('2FA Backup Codes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kWarning)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _backupRevealed = !_backupRevealed);
              if (!_backupRevealed) _startTimer(() => setState(() => _backupRevealed = false));
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_backupRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: kPrimary),
              const SizedBox(width: 4),
              Text(_backupRevealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: codes.map((c) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _backupRevealed
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurface, letterSpacing: 1)),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: c)); HapticFeedback.lightImpact(); }, child: const Icon(Icons.copy, size: 14, color: kOnSurfaceVariant)),
                  ])
                : const Text('••••-••••', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant, letterSpacing: 1)),
          );
        }).toList()),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AWS Root Key Detail Screen
// ═══════════════════════════════════════════════════════════════
class AwsRootKeyScreen extends StatefulWidget {
  const AwsRootKeyScreen({super.key});
  @override
  State<AwsRootKeyScreen> createState() => _AwsRootKeyScreenState();
}

class _AwsRootKeyScreenState extends State<AwsRootKeyScreen> {
  bool _secretRevealed = false;
  bool _accessIdRevealed = false;
  int _timer = 30;
  Timer? _t;

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  void _startTimer(void Function() onTimeout) {
    _t?.cancel();
    setState(() => _timer = 30);
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) { t.cancel(); if (mounted) onTimeout(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kOnSurface), onPressed: () => Navigator.pop(context)),
        title: const Text('AWS Root Key', style: TextStyle(color: kOnSurface)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: kOnSurfaceVariant), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFFF9900).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.cloud, size: 36, color: Color(0xFFFF9900))),
            const SizedBox(height: 12),
            const Text('AWS Root Key', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kOnSurface)),
            const SizedBox(height: 4), Text('Amazon Web Services', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
          ])),
          const SizedBox(height: 32),
          // Warning banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: kWarning.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 20, color: kWarning),
              const SizedBox(width: 10),
              Expanded(child: Text('Root keys grant FULL access to your AWS account. Never share publicly.', style: TextStyle(fontSize: 13, color: kWarning, fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 16),
          // Access Key ID
          _awsField(
            label: 'Access Key ID',
            value: 'AKIAIOSFODNN7EXAMPLE',
            revealed: _accessIdRevealed,
            onReveal: () { setState(() => _accessIdRevealed = true); _startTimer(() => setState(() => _accessIdRevealed = false)); },
          ),
          const SizedBox(height: 12),
          // Secret Access Key
          _awsField(
            label: 'Secret Access Key',
            value: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
            revealed: _secretRevealed,
            onReveal: () { setState(() => _secretRevealed = true); _startTimer(() => setState(() => _secretRevealed = false)); },
            isSecret: true,
          ),
          const SizedBox(height: 12),
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kOutlineVariant.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoRow('IAM User', 'admin@company.com'),
              const Divider(height: 20, color: kSurfaceContainerHighest),
              _infoRow('Region', 'us-east-1 (N. Virginia)'),
              const Divider(height: 20, color: kSurfaceContainerHighest),
              _infoRow('Console URL', 'https://console.aws.amazon.com'),
              const Divider(height: 20, color: kSurfaceContainerHighest),
              _infoRow('Created', 'May 15, 2024'),
            ]),
          ),
          const SizedBox(height: 24),
          if (_secretRevealed || _accessIdRevealed)
            Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined, size: 16, color: kWarning),
              const SizedBox(width: 8),
              Text('Auto-hide in $_timer s', style: const TextStyle(fontSize: 12, color: kWarning, fontWeight: FontWeight.w500)),
            ])),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _awsField({required String label, required String value, required bool revealed, required VoidCallback onReveal, bool isSecret = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSecret ? kWarning.withOpacity(0.3) : kOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kOnSurfaceVariant))),
          const Spacer(),
          GestureDetector(
            onTap: revealed ? null : onReveal,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(revealed ? Icons.visibility_off : Icons.visibility, size: 16, color: kPrimary),
              const SizedBox(width: 4),
              Text(revealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(revealed ? value : '••••••••••••••••••••••••••••', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'monospace', color: kOnSurface))),
          if (revealed)
            GestureDetector(
              onTap: () { Clipboard.setData(ClipboardData(text: value)); HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1))); },
              child: const Icon(Icons.copy, size: 18, color: kOnSurfaceVariant),
            ),
        ]),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
      Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurface))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// Recovery Codes Detail Screen
// ═══════════════════════════════════════════════════════════════
class RecoveryCodesScreen extends StatefulWidget {
  const RecoveryCodesScreen({super.key});
  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final codes = [
      ('Google', '8472-9910'),
      ('Google', '5531-0087'),
      ('Google', '2294-7763'),
      ('GitHub', '1108-4456'),
      ('GitHub', '6677-3321'),
      ('GitHub', '9901-5543'),
      ('Discord', '3344-8899'),
      ('Discord', '7755-1122'),
    ];

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kOnSurface), onPressed: () => Navigator.pop(context)),
        title: const Text('Recovery Codes', style: TextStyle(color: kOnSurface)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: kOnSurfaceVariant), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.grid_view, size: 36, color: Color(0xFF7B1FA2))),
            const SizedBox(height: 12),
            const Text('Recovery Codes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kOnSurface)),
            const SizedBox(height: 4), Text('Backup access codes', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
          ])),
          const SizedBox(height: 24),
          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: kWarning.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 20, color: kWarning),
              const SizedBox(width: 10),
              Expanded(child: Text('Store these codes safely. Each code works only once.', style: TextStyle(fontSize: 13, color: kWarning, fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 16),
          // Header row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Codes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kOnSurfaceVariant)),
            GestureDetector(
              onTap: () {
                final all = codes.map((c) => c.$2).join('\n');
                Clipboard.setData(ClipboardData(text: all));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All codes copied'), duration: Duration(seconds: 1)));
              },
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.copy_all, size: 16, color: kPrimary),
                SizedBox(width: 4),
                Text('Copy all', style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w500)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          _buildServiceSection('Google', codes.where((c) => c.$1 == 'Google').toList()),
          const SizedBox(height: 16),
          _buildServiceSection('GitHub', codes.where((c) => c.$1 == 'GitHub').toList()),
          const SizedBox(height: 16),
          _buildServiceSection('Discord', codes.where((c) => c.$1 == 'Discord').toList()),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildServiceSection(String service, List<(String, String)> codes) {
    final serviceIndex = {'Google': 0, 'GitHub': 1, 'Discord': 2}[service] ?? 0;
    final sectionColor = [const Color(0xFF4285F4), const Color(0xFF333333), const Color(0xFF5865F2)][serviceIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kOutlineVariant.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: sectionColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.verified_user, size: 16, color: sectionColor)),
          const SizedBox(width: 10),
          Text(service, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kOnSurface)),
          const Spacer(), Text('${codes.length} codes', style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant)),
        ]),
        const SizedBox(height: 12),
        ...codes.asMap().entries.map((entry) {
          final globalIndex = serviceIndex * 100 + entry.key;
          final isRevealed = _revealed.contains(globalIndex);
          final code = entry.value.$2;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: kSurfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: sectionColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isRevealed ? code : '••••-••••',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'monospace', color: isRevealed ? kOnSurface : kOnSurfaceVariant, letterSpacing: 1),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isRevealed) _revealed.remove(globalIndex);
                    else _revealed.add(globalIndex);
                  });
                },
                child: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: kPrimary),
              ),
              const SizedBox(width: 12),
              if (isRevealed)
                GestureDetector(
                  onTap: () { Clipboard.setData(ClipboardData(text: code)); HapticFeedback.lightImpact(); },
                  child: const Icon(Icons.copy, size: 16, color: kOnSurfaceVariant),
                ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Binance Account Detail Screen
// ═══════════════════════════════════════════════════════════════
class BinanceAccountScreen extends StatefulWidget {
  const BinanceAccountScreen({super.key});
  @override
  State<BinanceAccountScreen> createState() => _BinanceAccountScreenState();
}

class _BinanceAccountScreenState extends State<BinanceAccountScreen> {
  bool _passwordRevealed = false;
  bool _twoFaRevealed = false;
  int _timer = 30;
  Timer? _t;

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  void _startTimer(void Function() onTimeout) {
    _t?.cancel();
    setState(() => _timer = 30);
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) { t.cancel(); if (mounted) onTimeout(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kOnSurface), onPressed: () => Navigator.pop(context)),
        title: const Text('Binance Account', style: TextStyle(color: kOnSurface)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: kOnSurfaceVariant), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFF0B90B).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.currency_bitcoin, size: 36, color: Color(0xFFF0B90B))),
            const SizedBox(height: 12),
            const Text('Binance Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kOnSurface)),
            const SizedBox(height: 4), Text('alex@gmail.com', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
          ])),
          const SizedBox(height: 32),
          // Email
          _fieldCard(
            icon: Icons.alternate_email,
            label: 'Account Email',
            value: 'alex@gmail.com',
            onCopy: () { Clipboard.setData(ClipboardData(text: 'alex@gmail.com')); HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1))); },
          ),
          const SizedBox(height: 12),
          // Password
          _fieldCard(
            icon: Icons.lock_outline,
            label: 'Password',
            value: 'Bin@nce!Secure#9921',
            revealed: _passwordRevealed,
            onReveal: () { setState(() => _passwordRevealed = true); _startTimer(() => setState(() => _passwordRevealed = false)); },
            warning: true,
            onCopy: () { Clipboard.setData(ClipboardData(text: 'Bin@nce!Secure#9921')); HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1))); },
          ),
          const SizedBox(height: 12),
          // 2FA Backup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kWarning.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.security, size: 18, color: kWarning),
                const SizedBox(width: 8),
                const Text('2FA Backup Key', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kWarning)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _twoFaRevealed = !_twoFaRevealed);
                    if (!_twoFaRevealed) _startTimer(() => setState(() => _twoFaRevealed = false));
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_twoFaRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: kPrimary),
                    const SizedBox(width: 4),
                    Text(_twoFaRevealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text(
                    _twoFaRevealed ? 'JBSWY3DPEHPK3PXP' : '••••••••••••••••',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'monospace', color: kOnSurface, letterSpacing: 2),
                  ),
                ),
                if (_twoFaRevealed)
                  GestureDetector(
                    onTap: () { Clipboard.setData(ClipboardData(text: 'JBSWY3DPEHPK3PXP')); HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1))); },
                    child: const Icon(Icons.copy, size: 18, color: kOnSurfaceVariant),
                  ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kOutlineVariant.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoRow('Account Type', 'Verified'),
              const Divider(height: 20, color: kSurfaceContainerHighest),
              _infoRow('Created', 'Jan 12, 2023'),
              const Divider(height: 20, color: kSurfaceContainerHighest),
              _infoRow('Last Login', 'May 27, 2024'),
            ]),
          ),
          const SizedBox(height: 24),
          if (_passwordRevealed || _twoFaRevealed)
            Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined, size: 16, color: kWarning),
              const SizedBox(width: 8),
              Text('Auto-hide in $_timer s', style: const TextStyle(fontSize: 12, color: kWarning, fontWeight: FontWeight.w500)),
            ])),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _fieldCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool revealed = false,
    bool warning = false,
    VoidCallback? onReveal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning ? kWarning.withOpacity(0.3) : kOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: warning ? kWarning : kOnSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: warning ? kWarning : kOnSurfaceVariant)),
          const Spacer(),
          if (onReveal != null)
            GestureDetector(
              onTap: revealed ? null : onReveal,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(revealed ? Icons.visibility_off : Icons.visibility, size: 16, color: kPrimary),
                const SizedBox(width: 4),
                Text(revealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
              ]),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              revealed || onReveal == null ? value : '••••••••••••',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kOnSurface, letterSpacing: onReveal != null ? 0.5 : 0),
            ),
          ),
          if ((revealed || onReveal == null) && onCopy != null)
            GestureDetector(onTap: onCopy, child: const Icon(Icons.copy, size: 18, color: kOnSurfaceVariant)),
        ]),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurface)),
    ]);
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
      _AddSecretItem(icon: Icons.security, iconColor: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFF3CD), title: '2FA', subtitle: 'Store TOTP secrets and backup codes'),
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
  bool _importExpanded = false;
  bool _paymentsExpanded = false;
  bool _documentsExpanded = false;

  static const _iconColors = <Color>[
    Color(0xFF4285F4),
    Color(0xFF0D631B),
    Color(0xFFFF9900),
    Color(0xFF6A1B9A),
    Color(0xFF00796B),
    Color(0xFF1E88E5),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GhostKey', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kOnSurface)),
              Stack(children: [
                const Icon(Icons.notifications_outlined, size: 28, color: kOnSurface),
                Positioned(right: 2, top: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: kError, shape: BoxShape.circle))),
              ]),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Good morning,', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
          const Text('Alex', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kOnSurface)),
          const SizedBox(height: 24),

          // Import banner
          _buildImportSection(),
          const SizedBox(height: 24),

          // Quick actions
          const Text('Quick Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kOnSurface)),
          const SizedBox(height: 12),
          _actionTile(Icons.vpn_key, 'Login', 'Add a password', VaultCategory.password),
          _actionTile(Icons.alternate_email, 'Hide My Email', 'Generate a private relay', VaultCategory.password),
          _actionTile(Icons.note, 'Note', 'Save a secure note', VaultCategory.notes),

          ExpansionTile(
            title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w500)),
            leading: Icon(Icons.credit_card, color: _iconColors[4]),
            initiallyExpanded: _paymentsExpanded,
            onExpansionChanged: (v) => setState(() => _paymentsExpanded = v),
            children: [
              _actionTile(Icons.account_balance, 'Bank Account', 'Add banking details', VaultCategory.password),
              _actionTile(Icons.credit_card, 'Card', 'Add payment card', VaultCategory.password),
            ],
          ),

          ExpansionTile(
            title: const Text('Documents', style: TextStyle(fontWeight: FontWeight.w500)),
            leading: Icon(Icons.description, color: _iconColors[3]),
            initiallyExpanded: _documentsExpanded,
            onExpansionChanged: (v) => setState(() => _documentsExpanded = v),
            children: [
              _actionTile(Icons.book, 'Passport', 'Store passport info', VaultCategory.privateKeys),
              _actionTile(Icons.badge, 'ID Card', 'Store ID card info', VaultCategory.privateKeys),
              _actionTile(Icons.article, 'Drivers License', 'Store license info', VaultCategory.privateKeys),
            ],
          ),

          _actionTile(Icons.face, 'Identity', 'Manage your identity', VaultCategory.privateKeys),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildImportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.file_upload_outlined, color: kPrimary, size: 20)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Import from other password managers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kOnSurface))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _importExpanded = !_importExpanded),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: kPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text(_importExpanded ? 'Hide formats' : 'Learn more', style: const TextStyle(color: kPrimary)),
            ),
          ),
          if (_importExpanded) ...[
            const SizedBox(height: 12),
            const Text('Supported formats: CSV, JSON, 1Password (.1pif), Bitwarden, Dashlane, LastPass', style: TextStyle(fontSize: 12, color: kOnSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VaultCategory category) {
    return ListTile(
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: kPrimary, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: kOnSurface)),
      subtitle: Text(subtitle, style: const TextStyle(color: kOnSurfaceVariant, fontSize: 12)),
      trailing: const Icon(Icons.add_circle_outline, color: kPrimary),
      onTap: () => QuickAddService.instance.addAndShow(category),
    );
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
  bool _checkinReminders = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final primary = kPrimary;
    final onSurfaceVar = kOnSurfaceVariant;
    final surface = kSurface;
    final outlineVar = kOutlineVariant;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        title: Text('Settings', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF191C1D), letterSpacing: -0.01)),
      ),
      body: DefaultTextStyle(
        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF191C1D)),
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ProCard(),
          const SizedBox(height: 28),

          // Security
          _sectionHeader('Security', primary),
          const SizedBox(height: 8),
          _card([
            _row(Icons.fingerprint, 'PIN & biometric setup', subtitle: 'Secure your access', chevron: true, onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecuritySetupScreen()));
            }),
          ]),
          const SizedBox(height: 28),

          // Vault & Timer
          _sectionHeader('Vault & Timer', primary),
          const SizedBox(height: 8),
          _card([
            _row(Icons.timer, "Dead Man's Switch Duration", subtitle: 'Active: 6 Months', chevron: true, onTap: () {}),
          ]),
          const SizedBox(height: 28),

          // Data Management (DataSectionWidget: import/backup/export)
          _sectionHeader('Data Management', primary),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const DataSectionWidget(),
          ),
          const SizedBox(height: 28),

          // Support
          _sectionHeader('Support', primary),
          const SizedBox(height: 8),
          _card([
            _row(Icons.api, 'OpenRouter Test', chevron: true, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OpenRouterTestScreen()))),
          ]),
          const SizedBox(height: 28),

          // Notifications
          _sectionHeader('Notifications', primary),
          const SizedBox(height: 8),
          _card([
            _switchRow(Icons.event_available, 'Check-in Reminders', _checkinReminders, (v) => setState(() => _checkinReminders = v)),
          ]),
          const SizedBox(height: 28),

          // Account & Plan
          _sectionHeader('Account & Plan', primary),
          const SizedBox(height: 8),
          _card([
            _row(Icons.credit_card, 'Payment Methods', chevron: true),
          ]),
          const SizedBox(height: 28),

          // About
          _sectionHeader('About', onSurfaceVar),
          const SizedBox(height: 8),
          _card([
            _row(Icons.policy, 'Privacy Policy', trailing: const Icon(Icons.open_in_new, color: Color(0xFF40493D), size: 18), onTap: () {}),
            _divider(outlineVar),
            _row(Icons.gavel, 'Terms of Service', trailing: const Icon(Icons.open_in_new, color: Color(0xFF40493D), size: 18), onTap: () {}),
            _divider(outlineVar),
            _infoRow('Version', '1.0.4'),
            _infoRow('Release', 'Stable Release'),
          ]),
          const SizedBox(height: 32),

          // Sign Out
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (r) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDAD6),
                foregroundColor: const Color(0xFF93000A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 1,
                shadowColor: kError.withOpacity(0.15),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout, size: 20),
                SizedBox(width: 8),
                Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('GhostKey • Secure by Design', style: TextStyle(fontSize: 12, color: kOnSurfaceVariant.withOpacity(0.6)))),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 1.5)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _iconBadge(IconData icon, {Color? fg, Color? bg}) {
    final a = _accentFor(icon);
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: bg ?? a.bg, borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: fg ?? a.fg, size: 24),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, thickness: 1, color: color.withOpacity(0.1), indent: 64);
  }

  Widget _infoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF191C1D))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF191C1D))),
      ]),
    );
  }

  Widget _row(IconData icon, String title, {Widget? trailing, bool chevron = false, String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _iconBadge(icon),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF191C1D))),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF40493D))),
            ],
          ])),
          trailing ?? (chevron
              ? const Icon(Icons.chevron_right, color: Color(0xFF40493D), size: 20)
              : const SizedBox.shrink()),
        ]),
      ),
    );
  }

  Widget _switchRow(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _iconBadge(icon),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF191C1D)))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kPrimary,
            activeTrackColor: kPrimary.withOpacity(0.3),
          ),
        ]),
      ),
    );
  }

  _Accent _accentFor(IconData icon) {
    // Vivid, mockup-like tonal chips — no gray.
    if (icon == Icons.fingerprint) return _Accent(kPrimary, kPrimary.withOpacity(0.12));
    if (icon == Icons.timer) return _Accent(kTertiary, kTertiary.withOpacity(0.12));
    if (icon == Icons.api) return _Accent(kPrimary, kPrimary.withOpacity(0.12));
    if (icon == Icons.event_available) return _Accent(kPrimary, kPrimary.withOpacity(0.12));
    if (icon == Icons.credit_card) return _Accent(kTertiary, kTertiary.withOpacity(0.12));
    if (icon == Icons.policy || icon == Icons.gavel) return _Accent(kPrimary, kPrimary.withOpacity(0.12));
    return _Accent(kPrimary, kPrimary.withOpacity(0.12));
  }
}

class _Accent {
  final Color fg;
  final Color bg;
  const _Accent(this.fg, this.bg);
}

class _ProCard extends StatelessWidget {
  const _ProCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          child: const Icon(Icons.shield, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GhostKey Pro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
          Text('Active until Oct 2025', style: TextStyle(fontSize: 14, color: kOnSurfaceVariant)),
        ])),
        const Icon(Icons.chevron_right, color: Color(0xFF40493D), size: 22),
      ]),
    );
  }
}

