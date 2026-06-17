// ═══════════════════════════════════════════════════════════════
// SPLASH SCREEN — Brand logo on light surface, fades + scales in.
// Always shown on every launch (cold + warm) for 1.5s minimum.
// Waits for the heavy background inits to finish before navigating
// away so the home tab never renders before SQLite / icon registry
// are ready.
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart' show appReadyCompleter;

const Color _bgTop = Color(0xFFF8F9FA);
const Color _bgBottom = Color(0xFFF3F4F5);
const Color _ink = Color(0xFF191C1D);
const Color _muted = Color(0xFF40493D);
const Color _primary = Color(0xFF0D631B);

class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Widget Function(SharedPreferences prefs, bool hasPin, bool onboarded)
      resolveHome;
  const SplashScreen({
    super.key,
    required this.prefs,
    required this.resolveHome,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Small loading indicator that spins until [ready] flips to true.
/// Used by the splash to signal that the background inits (icons +
/// SQLite) are still running on the very first launch.
class _ReadySpinner extends StatefulWidget {
  final bool ready;
  const _ReadySpinner({required this.ready});

  @override
  State<_ReadySpinner> createState() => _ReadySpinnerState();
}

class _ReadySpinnerState extends State<_ReadySpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (!widget.ready) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _ReadySpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && _spin.isAnimating) {
      _spin.stop();
    } else if (!widget.ready && !_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ready) {
      // Fade-out: a quiet checkmark says "ready" without making the
      // splash feel busy.
      return const Icon(Icons.check_circle, size: 18, color: _primary);
    }
    return SizedBox(
      width: 18,
      height: 18,
      child: RotationTransition(
        turns: _spin,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_primary),
        ),
      ),
    );
  }
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // System UI matches the light gradient (icons dark so they read on white)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _opacity = CurvedAnimation(parent: _enter, curve: Curves.easeIn);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _enter.forward();

    // Show the splash for AT LEAST 1.5s for the brand impression, but do
    // NOT navigate until both (a) the min display time is up AND (b) the
    // background inits (icons + SQLite) have finished.
    _whenReadyToNavigate();
    // Rebuild when the completer flips so the spinner becomes a checkmark.
    appReadyCompleter.future.whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _whenReadyToNavigate() async {
    final minHold = Future.delayed(const Duration(milliseconds: 1500));
    await Future.wait([minHold, appReadyCompleter.future]);
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final hasPin = widget.prefs.getString('pin') != null;
    final onboarded = widget.prefs.getBool('onboarded') ?? false;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            widget.resolveHome(widget.prefs, hasPin, onboarded),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glow ring (pulses softly)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final t = _pulse.value;
                    return Container(
                      width: 220 + (t * 16),
                      height: 220 + (t * 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _primary.withOpacity(0.12 + t * 0.06),
                          _primary.withOpacity(0.0),
                        ]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Logo with scale-in (Hero matches the onboarding badge so the
                // route change animates the brand mark, not a hard cut).
                FadeTransition(
                  opacity: _opacity,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.7, end: 1.0)
                        .animate(_scale),
                    child: Hero(
                      tag: 'ghostkey-logo',
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          'assets/Canvas1.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Wordmark fades in slightly after logo
                FadeTransition(
                  opacity: _opacity,
                  child: const Text(
                    'GhostKey',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      height: 36 / 28,
                      letterSpacing: -0.25,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _opacity,
                  child: const Text(
                    'Your digital legacy secured.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _muted,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Tiny spinner so a slow first launch (loading 495 brand
                // icons + opening SQLite) doesn't look frozen. Stops
                // spinning the moment [appReadyCompleter] fires.
                _ReadySpinner(ready: appReadyCompleter.isCompleted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
