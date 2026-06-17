import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show
    rootNavigatorKey,
    MainShell,
    kSurface,
    kOnSurface,
    kPrimary,
    kSecondary,
    kSurfaceContainerLow,
    kSurfaceContainerHigh,
    kOutlineVariant,
    kOutline,
    kOnSurfaceVariant;
import '../pin_unlock_screen.dart' show PinScreen, PinScreenMode;

enum AuthMode { signup, signin }

class AuthScreen extends StatefulWidget {
  final AuthMode mode;
  const AuthScreen({super.key, required this.mode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;

  void _goToPinSetup() {
    final prefs = context.read<SharedPreferences>();
    prefs.setBool('onboarded', true);
    rootNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => PinScreen(
          title: 'Create your PIN',
          subtitle: 'A 6-digit code to unlock your vault',
          mode: PinScreenMode.setup,
          onUnlock: (pin) {
            prefs.setString('pin', pin);
            rootNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
          onSkip: () {
            rootNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onGoogle() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _busy = false);
    _goToPinSetup();
  }

  Future<void> _onEmail() async {
    final isSignup = widget.mode == AuthMode.signup;
    final result = await rootNavigatorKey.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => isSignup
            ? _EmailFormScreen(mode: widget.mode) // signup: full form
            : const _EmailEntryScreen(), // signin: 2-step flow
      ),
    );
    if (result == true) _goToPinSetup();
  }

  Future<void> _onPhone() async {
    final isSignup = widget.mode == AuthMode.signup;
    final result = await rootNavigatorKey.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => isSignup
            ? _PhoneFormScreen(mode: widget.mode) // signup: combined
            : const _PhoneEntryScreen(), // signin: 2-step flow
      ),
    );
    if (result == true) _goToPinSetup();
  }

  void _onSkip() => _goToPinSetup();

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.mode == AuthMode.signup;
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Layer 1: Base vertical gradient (surface → surface-container-low)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kSurface, kSurfaceContainerLow],
                ),
              ),
            ),
          ),
          // Layer 2: Subtle mesh gradient overlay (primary-fixed + on-primary-fixed)
          const Positioned.fill(child: IgnorePointer(child: _MeshBackground())),
          // Layer 3: Foreground content
          Column(
            children: [
              // Top nav (M3 manual back button)
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
              // Scrollable content (max-width 28rem = 448px)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          // Branding identity (hero)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              children: [
                                const _ShieldHero(),
                                const SizedBox(height: 24),
                                // Title (M3 headline-lg-mobile: 28/36/600)
                                Text(
                                  isSignup ? 'Create your account' : 'Sign in to GhostKey',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: kOnSurface,
                                    height: 36 / 28,
                                    letterSpacing: -0.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Subtitle (M3 body-lg: 16/24/400)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    isSignup
                                        ? 'Pick a method to secure your digital legacy.\nYou can change this later.'
                                        : 'Access your digital legacy across all devices with high-trust security.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: kOnSurfaceVariant,
                                      height: 24 / 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ─── Auth methods (M3 outlined cards) ───
                          _AuthCard(
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: CustomPaint(painter: _GoogleGLogoPainter()),
                            ),
                            label: isSignup ? 'Continue with Google' : 'Sign in with Google',
                            onTap: _busy ? null : _onGoogle,
                          ),
                          const SizedBox(height: 16),
                          _AuthCard(
                            leading: const Icon(Icons.mail, size: 24, color: kOnSurfaceVariant),
                            label: isSignup ? 'Continue with Email' : 'Sign in with Email',
                            onTap: _busy ? null : _onEmail,
                          ),
                          const SizedBox(height: 16),
                          _AuthCard(
                            leading: const Icon(Icons.smartphone, size: 24, color: kOnSurfaceVariant),
                            label: isSignup ? 'Continue with Phone' : 'Sign in with Phone',
                            onTap: _busy ? null : _onPhone,
                          ),
                          // ─── Separator ───
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: kOutlineVariant, height: 1)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kOutline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: kOutlineVariant, height: 1)),
                              ],
                            ),
                          ),
                          // ─── Continue offline (highlighted) ───
                          _AuthCard(
                            leading: const Icon(Icons.cloud_off, size: 24, color: kPrimary),
                            label: 'Continue offline',
                            highlighted: true,
                            onTap: _busy ? null : _onSkip,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ─── Footer security banner ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                color: Colors.white, // surface-container-lowest
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 18, color: kOutline),
                        SizedBox(width: 8),
                        Text(
                          'End-to-end encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            color: kOutline,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Zero-knowledge architecture. GhostKey never sees your data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: kOnSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // OS nav bar spacer
                    Center(
                      child: Container(
                        width: 128,
                        height: 6,
                        decoration: BoxDecoration(
                          color: kOnSurface.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// M3 SHIELD HERO — 4-layer (glow → ring → badge → shield icon)
// ═══════════════════════════════════════════════════════════════
class _ShieldHero extends StatelessWidget {
  const _ShieldHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(alignment: Alignment.center, children: [
        // Layer 1: Outer soft glow (scale 1.25, blur-xl effect via boxShadow)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimary.withOpacity(0.05),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.10),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        // Layer 2: Border ring (2px primary/10)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary.withOpacity(0.10), width: 2),
            ),
          ),
        ),
        // Layer 3: Core badge (white, shadow-sm)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.shield, size: 48, color: kPrimary),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MESH BACKGROUND — subtle primary-fixed + on-primary-fixed radials
// ═══════════════════════════════════════════════════════════════
class _MeshBackground extends StatelessWidget {
  const _MeshBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Top-center: primary-fixed (#A3F69C) radial at 15% opacity
      Positioned(
        top: -120,
        left: 0,
        right: 0,
        height: 500,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 0.9,
              colors: [
                const Color(0xFFA3F69C).withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Bottom-right: on-primary-fixed (#CBFFC2) radial at 10% opacity
      Positioned(
        bottom: -120,
        right: -120,
        width: 400,
        height: 400,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFCBFFC2).withOpacity(0.10),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// M3 AUTH CARD — outlined button with chevron_right
// ═══════════════════════════════════════════════════════════════
class _AuthCard extends StatefulWidget {
  final Widget leading;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  const _AuthCard({
    required this.leading,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.highlighted;
    final disabled = widget.onTap == null;
    final Color bg = highlighted
        ? const Color(0xFFE8F5E9) // on-tertiary-container
        : _pressed
            ? kSurfaceContainerHigh // hover state
            : Colors.white; // surface-container-lowest
    final Color border = highlighted
        ? kPrimary.withOpacity(0.20)
        : kOutlineVariant;
    final Color textColor = highlighted ? kPrimary : kOnSurface;
    final Color chevronColor = highlighted ? kPrimary : kOutline;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (p) => setState(() => _pressed = p),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
              boxShadow: highlighted
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              children: [
                SizedBox(width: 24, height: 24, child: widget.leading),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 18, // headline-sm
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CIRCLE ICON BUTTON — M3 surface-container-high bg, round
// ═══════════════════════════════════════════════════════════════
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: kSurfaceContainerHigh,
          ),
          child: Icon(icon, size: 22, color: kOnSurface),
        ),
      ),
    );
  }
}

// Real Google G logo with 4 brand colors
class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final center = Offset(w / 2, h / 2);

    // Outer ring: blue (top), green (right), yellow (bottom-right), red (left)
    // We'll draw 4 arcs, each in one color
    final rect = Rect.fromCircle(center: center, radius: r - 1);

    // Blue (top to right)
    final p1 = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -1.5708, 1.5708, false, p1);

    // Green (right to bottom)
    final p2 = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 1.5708, false, p2);

    // Yellow (bottom to left)
    final p3 = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 1.5708, 1.5708, false, p3);

    // Red (left to top)
    final p4 = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 3.1416, 1.5708, false, p4);

    // Inner horizontal bar (blue, the tail of the G)
    final p5 = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final barY = h * 0.5;
    canvas.drawLine(
      Offset(w * 0.42, barY),
      Offset(w * 0.78, barY),
      p5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Email Form Screen ───
class _EmailFormScreen extends StatefulWidget {
  final AuthMode mode;
  const _EmailFormScreen({required this.mode});
  @override
  State<_EmailFormScreen> createState() => _EmailFormScreenState();
}

class _EmailFormScreenState extends State<_EmailFormScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Rebuild on password changes so the strength meter updates live
    _passCtrl.addListener(_onPassChanged);
  }

  void _onPassChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passCtrl.removeListener(_onPassChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  int _passwordScore() {
    final v = _passCtrl.text;
    if (v.isEmpty) return 0;
    int score = 1;
    if (v.length >= 8) score = 2;
    if (v.length >= 12 && v.contains(RegExp(r'[A-Z]')) && v.contains(RegExp(r'[0-9]'))) {
      score = 3;
    }
    if (v.length >= 16 && v.contains(RegExp(r'[^A-Za-z0-9]'))) score = 4;
    return score;
  }

  Future<void> _submit() async {
    final missingName = widget.mode == AuthMode.signup && _nameCtrl.text.trim().isEmpty;
    if (missingName || _emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all fields')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _busy = false);
    // For signup, push OTP screen to verify email
    if (widget.mode == AuthMode.signup) {
      final email = _emailCtrl.text.trim();
      final result = await rootNavigatorKey.currentState!.push<bool>(
        MaterialPageRoute(
          builder: (_) => _CodeEntryScreen(
            destination: email,
            kind: OtpKind.email,
          ),
        ),
      );
      if (result == true && mounted) Navigator.of(context).pop(true);
      return;
    }
    // For signin, just pop
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.mode == AuthMode.signup;
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header: back button + GhostKey logo ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.shield, size: 28, color: kPrimary),
                    const SizedBox(width: 6),
                    const Text(
                      'GhostKey',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kPrimary),
                    ),
                  ],
                ),
              ),
            ),
            // ─── Main content ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Branding text
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Text(
                                isSignup ? 'Create your account' : 'Sign in to GhostKey',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: kOnSurface,
                                  height: 36 / 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Text(
                                  isSignup
                                      ? 'Start securing your digital legacy with end-to-end vault protection.'
                                      : 'Enter your credentials to access your vault',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: kOnSurfaceVariant,
                                    height: 20 / 14,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ─── Form card ───
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kOutlineVariant.withOpacity(0.30)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full Name (signup only)
                              if (isSignup) ...[
                                const _FieldLabelM3('Full Name'),
                                const SizedBox(height: 4),
                                _M3Input(
                                  controller: _nameCtrl,
                                  hint: 'Enter your full name',
                                  icon: Icons.person_outline,
                                  keyboardType: TextInputType.name,
                                ),
                                const SizedBox(height: 12),
                              ],
                              // Email
                              _FieldLabelM3(isSignup ? 'Email Address' : 'Email'),
                              const SizedBox(height: 4),
                              _M3Input(
                                controller: _emailCtrl,
                                hint: 'email@example.com',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                              ),
                              const SizedBox(height: 12),
                              // Master Password (signup) / Password (signin)
                              _FieldLabelM3(isSignup ? 'Master Password' : 'Password'),
                              const SizedBox(height: 4),
                              _M3Input(
                                controller: _passCtrl,
                                hint: isSignup ? 'Min. 12 characters' : '••••••••',
                                icon: Icons.lock_outline,
                                obscure: _obscure,
                                suffix: IconButton(
                                  splashRadius: 20,
                                  icon: Icon(
                                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: kOnSurfaceVariant,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              // Password strength meter (signup only)
                              if (isSignup) ...[
                                const SizedBox(height: 12),
                                _PasswordStrengthMeter(score: _passwordScore()),
                              ],
                              // Primary submit button
                              const SizedBox(height: 16),
                              _GradientSubmitButton(
                                label: isSignup ? 'Create Account' : 'Sign in',
                                icon: Icons.arrow_forward,
                                loading: _busy,
                                onPressed: _busy ? null : _submit,
                              ),
                              // Divider + Google button (signup only)
                              if (isSignup) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(child: Divider(color: kOutlineVariant, height: 1)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'or continue with',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: kOnSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: kOutlineVariant, height: 1)),
                                    ],
                                  ),
                                ),
                                _GoogleOutlinedButton(
                                  label: 'Sign up with Google',
                                  onTap: _busy ? null : () => Navigator.of(context).pop(true),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // ─── Footer sign in link ───
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'Already have an account? ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kOnSurfaceVariant,
                                  height: 20 / 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign in',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // Go to the auth methods page in signin mode
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) => const AuthScreen(mode: AuthMode.signin),
                                          ),
                                          (r) => false,
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // ─── Security badges row ───
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Opacity(
                            opacity: 0.4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SecurityBadge(icon: Icons.verified_user_outlined, label: 'AES-256 Bit'),
                                SizedBox(width: 24),
                                _SecurityBadge(icon: Icons.lock_reset_outlined, label: 'Zero Knowledge'),
                                SizedBox(width: 24),
                                _SecurityBadge(icon: Icons.family_restroom_outlined, label: 'Legacy Safe'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// M3 FIELD LABEL — label-md style (12/16/500, on-surface-variant)
// ═══════════════════════════════════════════════════════════════
class _FieldLabelM3 extends StatelessWidget {
  final String text;
  const _FieldLabelM3(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: kOnSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// M3 INPUT — rounded-lg, bg surface-container-low, leading icon,
// focus changes to surface-container + primary/20 ring
// ═══════════════════════════════════════════════════════════════
class _M3Input extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool autocorrect;

  const _M3Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.autocorrect = true,
  });

  @override
  State<_M3Input> createState() => _M3InputState();
}

class _M3InputState extends State<_M3Input> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: focused ? Colors.white : kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focused ? kPrimary.withOpacity(0.20) : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        autocorrect: widget.autocorrect,
        style: const TextStyle(color: kOnSurface, fontSize: 14, fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: kOnSurfaceVariant, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(widget.icon, size: 20, color: kOnSurfaceVariant),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PASSWORD STRENGTH METER — 4-bar live strength indicator
// Score: 0=empty, 1=any, 2=8+, 3=12+upper+num, 4=16+symbol
// ═══════════════════════════════════════════════════════════════
class _PasswordStrengthMeter extends StatelessWidget {
  final int score;
  const _PasswordStrengthMeter({required this.score});

  static const _tertiary = Color(0xFF4D5950);
  static const _secondary = Color(0xFF2A6B2C);
  static const _barEmpty = Color(0xFFE1E3E4); // surface-container-highest

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final int barsLit;

    switch (score) {
      case 1:
        label = 'Weak';
        color = const Color(0xFFBA1A1A); // error
        barsLit = 1;
        break;
      case 2:
        label = 'Fair';
        color = _tertiary;
        barsLit = 2;
        break;
      case 3:
        label = 'Strong';
        color = _secondary;
        barsLit = 3;
        break;
      case 4:
        label = 'Ultra Secure';
        color = kPrimary;
        barsLit = 4;
        break;
      default:
        label = 'Too weak';
        color = kOnSurfaceVariant;
        barsLit = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Security Strength',
              style: TextStyle(
                fontSize: 12,
                color: kOnSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < barsLit ? color : _barEmpty,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRADIENT SUBMIT BUTTON — security-gradient (primary → primary-container)
// ═══════════════════════════════════════════════════════════════
class _GradientSubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const _GradientSubmitButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D631B), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(icon, size: 20, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GOOGLE OUTLINED BUTTON — for "Sign up with Google"
// ═══════════════════════════════════════════════════════════════
class _GoogleOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GoogleOutlinedButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kOutlineVariant.withOpacity(0.50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: _GoogleGLogoPainter()),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kOnSurface,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECURITY BADGE — icon + uppercase label, used in footer row
// ═══════════════════════════════════════════════════════════════
class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: kOnSurface),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: kOnSurface,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF40493D)),
    );
  }
}

// ─── Phone Form Screen ───
class _PhoneFormScreen extends StatefulWidget {
  final AuthMode mode;
  const _PhoneFormScreen({required this.mode});
  @override
  State<_PhoneFormScreen> createState() => _PhoneFormScreenState();
}

class _PhoneFormScreenState extends State<_PhoneFormScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phoneCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeSent = true;
    });
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.mode == AuthMode.signup;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSignup ? 'Sign up with Phone' : 'Sign in with Phone',
          style: const TextStyle(color: Color(0xFF191C1D), fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D631B).withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D631B).withOpacity(0.10),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.phone_outlined, size: 32, color: Color(0xFF0D631B)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSignup ? 'Verify your phone' : 'Sign in with SMS',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF191C1D), letterSpacing: -0.2),
              ),
              const SizedBox(height: 6),
              Text(
                isSignup
                    ? "We'll text you a verification code"
                    : 'Enter your phone to receive a sign-in code',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF707A6C), height: 1.4),
              ),
              const SizedBox(height: 28),
              if (!_codeSent) ...[
                _FieldLabel('Phone number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Color(0xFF191C1D), fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '+1 555 123 4567',
                    hintStyle: const TextStyle(color: Color(0xFFBFCABA), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D631B), width: 1.5),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(Icons.phone_outlined, color: Color(0xFF707A6C), size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _sendCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D631B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send verification code',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ] else ...[
                Text(
                  'We sent a code to ${_phoneCtrl.text}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF40493D)),
                ),
                const SizedBox(height: 20),
                _FieldLabel('Verification code'),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF191C1D),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: const TextStyle(color: Color(0xFFBFCABA), fontSize: 26, letterSpacing: 12),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D631B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D631B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify and continue',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () {
                    setState(() {
                      _codeSent = false;
                      _codeCtrl.clear();
                    });
                  },
                  child: const Text('Change number', style: TextStyle(color: Color(0xFF0D631B), fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SIGN-IN BACKGROUND — two large blur radial gradients
// primary-fixed-dim top-right, secondary-fixed bottom-left
// ═══════════════════════════════════════════════════════════════
class _SignInBackground extends StatelessWidget {
  const _SignInBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Top-right: primary-fixed-dim (#88D982) at 10%
      Positioned(
        top: -120,
        right: -120,
        width: 450,
        height: 450,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF88D982).withOpacity(0.10),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Bottom-left: secondary-fixed (#ACF4A4) at 10%
      Positioned(
        bottom: -120,
        left: -120,
        width: 450,
        height: 450,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFACF4A4).withOpacity(0.10),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// EMAIL ENTRY SCREEN (signin step 1) — single email field
// ═══════════════════════════════════════════════════════════════
class _EmailEntryScreen extends StatefulWidget {
  const _EmailEntryScreen();
  @override
  State<_EmailEntryScreen> createState() => _EmailEntryScreenState();
}

class _EmailEntryScreenState extends State<_EmailEntryScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your password')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _busy = false);
    // Email + password verified — pop back to AuthScreen which routes to PIN setup
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Background blur gradients
          const Positioned.fill(child: IgnorePointer(child: _SignInBackground())),
          // Content
          Column(
            children: [
              // Top nav
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
              // Brand identity
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32), // primary-container
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 40,
                        color: Color(0xFFCBFFC2), // on-primary-container
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'GhostKey',
                      style: TextStyle(
                        fontSize: 24,
                        height: 32 / 24,
                        fontWeight: FontWeight.w600,
                        color: kOnSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline
                      const Text(
                        'Sign in with Email',
                        style: TextStyle(
                          fontSize: 28,
                          height: 36 / 28,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Access your digital legacy',
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Email field
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 16, color: kOnSurface),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(color: kOnSurfaceVariant, fontSize: 16),
                          floatingLabelStyle: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: kSurfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kPrimary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _continue(),
                        style: const TextStyle(fontSize: 16, color: kOnSurface),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: kOnSurfaceVariant, fontSize: 16),
                          floatingLabelStyle: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: kSurfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kPrimary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          suffixIcon: IconButton(
                            splashRadius: 20,
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20,
                              color: kOnSurfaceVariant,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password reset coming soon')),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _continue,
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.10),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Sign up link
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(
                              fontSize: 14,
                              color: kOnSurfaceVariant,
                              height: 20 / 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Jump straight to the Create Account email form
                                    // (skip the auth methods page)
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const _EmailFormScreen(mode: AuthMode.signup),
                                      ),
                                      (r) => false,
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16, color: kOutline),
                        SizedBox(width: 6),
                        Text(
                          'End-to-end encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            color: kOutline,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Decorative pill
                    Container(
                      width: 96,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E3E4), // surface-variant
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PASSWORD ENTRY SCREEN (signin step 2) — password field
// ═══════════════════════════════════════════════════════════════
class _PasswordEntryScreen extends StatefulWidget {
  final String email;
  const _PasswordEntryScreen({required this.email});
  @override
  State<_PasswordEntryScreen> createState() => _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends State<_PasswordEntryScreen> {
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your password')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _SignInBackground())),
          Column(
            children: [
              // Top nav
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
              // Form
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline
                      const Text(
                        'Enter your password',
                        style: TextStyle(
                          fontSize: 28,
                          height: 36 / 28,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Email + Change link
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: kOnSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text(
                            ' · ',
                            style: TextStyle(fontSize: 14, color: kOnSurfaceVariant),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 14,
                                color: kPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Password field
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        autofocus: true,
                        style: const TextStyle(fontSize: 16, color: kOnSurface),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: kOnSurfaceVariant, fontSize: 16),
                          floatingLabelStyle: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: kSurfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kPrimary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          suffixIcon: IconButton(
                            splashRadius: 20,
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20,
                              color: kOnSurfaceVariant,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _signIn,
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Forgot password link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password reset coming soon')),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 14,
                              color: kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16, color: kOutline),
                        SizedBox(width: 6),
                        Text(
                          'End-to-end encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            color: kOutline,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 96,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E3E4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHONE NUMBER FORMATTER — formats digits as (XXX) XXX-XXXX
// ═══════════════════════════════════════════════════════════════
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    if (digits.length > 10) {
      return oldValue;
    }

    String formatted;
    if (digits.length >= 7) {
      formatted = '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length >= 4) {
      formatted = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      formatted = digits;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHONE INPUT CONTAINER — country picker (left) + phone input
// Border + ring changes on focus (matches HTML focus-within)
// ═══════════════════════════════════════════════════════════════
class _PhoneInputContainer extends StatefulWidget {
  final TextEditingController controller;
  const _PhoneInputContainer({required this.controller});

  @override
  State<_PhoneInputContainer> createState() => _PhoneInputContainerState();
}

class _PhoneInputContainerState extends State<_PhoneInputContainer> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? kPrimary : kOutlineVariant,
          width: _focused ? 2 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: kPrimary.withOpacity(0.10), blurRadius: 0, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        children: [
          // Country picker (left)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: kOutlineVariant)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+1',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kOnSurface),
                ),
                SizedBox(width: 4),
                Icon(Icons.expand_more, size: 18, color: kOnSurfaceVariant),
              ],
            ),
          ),
          // Phone input (right)
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              inputFormatters: [_PhoneNumberFormatter()],
              style: const TextStyle(fontSize: 16, color: kOnSurface),
              decoration: const InputDecoration(
                hintText: '(555) 000-0000',
                hintStyle: TextStyle(color: kOnSurfaceVariant, fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PHONE ENTRY SCREEN (signin step 1) — matches HTML exactly
// ═══════════════════════════════════════════════════════════════
class _PhoneEntryScreen extends StatefulWidget {
  const _PhoneEntryScreen();
  @override
  State<_PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<_PhoneEntryScreen> {
  final _phoneCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _formattedPhone {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return _phoneCtrl.text;
    return '+1 $digits';
  }

  Future<void> _sendCode() async {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _busy = false);
    final result = await rootNavigatorKey.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => _CodeEntryScreen(
          destination: _formattedPhone,
          kind: OtpKind.phone,
        ),
      ),
    );
    if (result == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Same background as email signin for visual consistency
          const Positioned.fill(child: IgnorePointer(child: _SignInBackground())),
          // Bottom atmospheric gradient (matches HTML)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 256,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      kPrimary.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              // Top nav
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Branding
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32), // primary-container
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.shield,
                                size: 40,
                                color: Color(0xFFCBFFC2), // on-primary-container
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Sign in with Phone',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                height: 36 / 28,
                                fontWeight: FontWeight.w600,
                                color: kOnSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Secure access to your GhostKey vault',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                color: kOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Phone label
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: kOnSurfaceVariant,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Phone input
                      _PhoneInputContainer(controller: _phoneCtrl),
                      const SizedBox(height: 24),
                      // Send code button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _sendCode,
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Send Verification Code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Footer notes
                      const Text(
                        "Standard SMS rates may apply. By continuing, you agree to GhostKey's Terms of Service.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: kOutline,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Trust banner (secondary-container style)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFACF4A4).withOpacity(0.30), // secondary-container/30
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFACF4A4).withOpacity(0.50), // secondary-container/50
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 20, color: kSecondary),
                            SizedBox(width: 8),
                            Text(
                              'End-to-end encrypted',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kSecondary,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// OTP ENTRY SCREEN — 6-box OTP + custom keypad
// Reusable for email verification and phone verification
// ═══════════════════════════════════════════════════════════════
enum OtpKind { email, phone }

class _CodeEntryScreen extends StatefulWidget {
  final String destination; // email address or phone number
  final OtpKind kind;
  const _CodeEntryScreen({required this.destination, required this.kind});
  @override
  State<_CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends State<_CodeEntryScreen> {
  // 6 OTP input controllers and focus nodes
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocuses =
      List.generate(6, (_) => FocusNode());
  final List<VoidCallback> _focusListeners = [];

  int _currentIdx = 0;
  bool _busy = false;

  // Resend countdown
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // Wire focus listeners for each OTP box
    for (var i = 0; i < _otpFocuses.length; i++) {
      final idx = i;
      void listener() {
        if (mounted) {
          setState(() {
            if (_otpFocuses[idx].hasFocus) _currentIdx = idx;
          });
        }
      }
      _otpFocuses[idx].addListener(listener);
      _focusListeners.add(listener);
    }
    _startResendCountdown();
    // Auto-focus first input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocuses[0].requestFocus();
    });
  }

  void _startResendCountdown() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (var i = 0; i < _otpFocuses.length; i++) {
      _otpFocuses[i].removeListener(_focusListeners[i]);
      _otpFocuses[i].dispose();
    }
    for (final c in _otpCtrls) {
      c.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _formattedDestination {
    if (widget.kind == OtpKind.email) {
      return widget.destination;
    }
    final digits = widget.destination.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return widget.destination;
    return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, digits.length.clamp(6, 10))}';
  }

  void _onDigit(String digit) {
    if (_currentIdx >= 6) return;
    setState(() {
      _otpCtrls[_currentIdx].text = digit;
      if (_currentIdx < 5) {
        _currentIdx++;
        _otpFocuses[_currentIdx].requestFocus();
      }
    });
    // Auto-submit when all 6 boxes are filled
    if (_otpCtrls.every((c) => c.text.isNotEmpty)) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_currentIdx < 0) return;
    setState(() {
      if (_otpCtrls[_currentIdx].text.isNotEmpty) {
        _otpCtrls[_currentIdx].clear();
      } else if (_currentIdx > 0) {
        _currentIdx--;
        _otpCtrls[_currentIdx].clear();
        _otpFocuses[_currentIdx].requestFocus();
      }
    });
  }

  Future<void> _verify() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  void _resend() {
    if (_resendSeconds > 0) return;
    _startResendCountdown();
    for (final c in _otpCtrls) {
      c.clear();
    }
    setState(() => _currentIdx = 0);
    _otpFocuses[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code resent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Decorative shield watermark (rotated 12deg, low opacity)
          Positioned(
            top: 96,
            right: -48,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: Transform.rotate(
                  angle: 12 * 3.14159265 / 180, // 12 degrees
                  child: const Icon(
                    Icons.shield,
                    size: 180,
                    color: kOnSurface,
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // ─── Top app bar (back + GhostKey wordmark + spacer) ───
              SafeArea(
                bottom: false,
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back,
                              size: 24,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'GhostKey',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer for centering
                    ],
                  ),
                ),
              ),
              // ─── Form ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline
                      Text(
                        widget.kind == OtpKind.email
                            ? 'Verify your Email'
                            : 'Verify your Phone',
                        style: const TextStyle(
                          fontSize: 28,
                          height: 36 / 28,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle with bold destination
                      Text.rich(
                        TextSpan(
                          text: 'Enter the 6-digit code sent to ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: kOnSurfaceVariant,
                            height: 20 / 14,
                          ),
                          children: [
                            TextSpan(
                              text: _formattedDestination,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kOnSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // ─── 6 OTP input boxes ───
                      Row(
                        children: List.generate(6, (i) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                              child: _OtpBox(
                                controller: _otpCtrls[i],
                                focusNode: _otpFocuses[i],
                              ),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      // ─── Verify button ───
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _verify,
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Verify & Continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ─── Resend link (with countdown) ───
                      Center(
                        child: GestureDetector(
                          onTap: _resendSeconds > 0 ? null : _resend,
                          child: Text(
                            _resendSeconds > 0
                                ? 'Resend code in 0:${_resendSeconds.toString().padLeft(2, '0')}'
                                : 'Resend code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _resendSeconds > 0
                                  ? kOnSurfaceVariant
                                  : kPrimary,
                              decoration: _resendSeconds > 0
                                  ? null
                                  : TextDecoration.underline,
                              decorationColor: kPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ─── Numeric keypad ───
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE7E8E9), // surface-container-high
                  border: Border(top: BorderSide(color: kOutlineVariant)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: _buildKeypad(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _KeypadButton(label: '1', onTap: () => _onDigit('1')),
        _KeypadButton(label: '2', onTap: () => _onDigit('2')),
        _KeypadButton(label: '3', onTap: () => _onDigit('3')),
        _KeypadButton(label: '4', onTap: () => _onDigit('4')),
        _KeypadButton(label: '5', onTap: () => _onDigit('5')),
        _KeypadButton(label: '6', onTap: () => _onDigit('6')),
        _KeypadButton(label: '7', onTap: () => _onDigit('7')),
        _KeypadButton(label: '8', onTap: () => _onDigit('8')),
        _KeypadButton(label: '9', onTap: () => _onDigit('9')),
        const SizedBox.shrink(), // Empty space
        _KeypadButton(label: '0', onTap: () => _onDigit('0')),
        _KeypadButton(icon: Icons.backspace_outlined, onTap: _onBackspace),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// OTP BOX — single 1:1 input with focus-state styling
// ═══════════════════════════════════════════════════════════════
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const _OtpBox({required this.controller, required this.focusNode});

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _focused ? kSurface : kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(
              color: _focused ? kPrimary : Colors.transparent,
              width: 2,
            ),
          ),
          boxShadow: _focused
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          readOnly: true, // Custom keypad handles input
          showCursor: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w600,
            color: kOnSurface,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KEYPAD BUTTON — numeric key or backspace
// ═══════════════════════════════════════════════════════════════
class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _KeypadButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 24, color: kOnSurfaceVariant)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w600,
                    color: kOnSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
